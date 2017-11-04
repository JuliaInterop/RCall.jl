module RPrompt

import Base: LineEdit, REPL, REPLCompletions
import DataStructures: OrderedDict
import ..REvalError
import ..Const
import ..RCall:
    libR,
    rparse_p,
    reval_p,
    findNamespace,
    rcall_p,
    rprint,
    rcopy,
    render,
    prepare_inline_julia_code,
    RParseIncomplete,
    RException,
    RParseError,
    REvalError,
    RParseEOF


function simple_showerror(io::IO, er)
    Base.with_output_color(:red, io) do io
        print(io, "ERROR: ")
        showerror(io, er)
        println(io)
    end
end

function parse_status(script::String)
    status = :ok
    try
        render(script)
    catch ex
        if isa(ex, RParseIncomplete)
            status = :incomplete
        else
            status = :error
        end
    end
    status
end

function repl_eval(script::String, stdout::IO, stderr::IO)
    local status
    local val
    try
        script, symdict = render(script)
        if length(symdict) > 0
            eval(Main, prepare_inline_julia_code(symdict))
        end
        val = reval_p(rparse_p(script), Const.GlobalEnv.p)
        # print if the last expression is visible
        if unsafe_load(cglobal((:R_Visible, libR),Int)) == 1
             rprint(stdout, val)
        end
    catch ex
        if isa(ex, REvalError)
            println(stderr, ex.msg)
        elseif isa(ex, RParseIncomplete) || isa(ex, RParseError)  || isa(ex, RParseEOF)
            println(stderr, "Error: " * ex.msg)
        else
            simple_showerror(stderr, ex)
        end
    finally
        return nothing
    end
end

function bracketed_paste_callback(s, o...)
    input = LineEdit.bracketed_paste(s)
    sbuffer = LineEdit.buffer(s)
    curspos = position(sbuffer)
    seek(sbuffer, 0)
    shouldeval = (nb_available(sbuffer) == curspos && search(sbuffer, UInt8('\n')) == 0)
    seek(sbuffer, curspos)
    if curspos == 0
        # if pasting at the beginning, strip leading whitespace
        input = lstrip(input)
    end

    if !shouldeval
        LineEdit.edit_insert(s, input)
        return
    end

    LineEdit.edit_insert(sbuffer, input)
    input = String(take!(sbuffer))

    oldpos = start(input)
    nextpos = 0
    # parse the input line by line
    while !done(input, oldpos)
        nextpos = search(input, '\n', nextpos+1)
        if nextpos == 0
            nextpos = endof(input)
        end
        block = input[oldpos:nextpos]
        status = parse_status(block)

        if status == :error  || (status == :incomplete && done(input, nextpos+1)) ||
                (done(input, nextpos+1) && !endswith(input, '\n'))
            # error / continue but not the end / at the end but no new line
            LineEdit.replace_line(s, input[oldpos:end])
            LineEdit.refresh_line(s)
            break
        elseif status == :incomplete && !done(input, nextpos+1)
            continue
        end

        if !isempty(strip(block))
            # put the line on the screen and history
            LineEdit.replace_line(s, strip(block))
            LineEdit.commit_line(s)
            # execute the statement
            terminal = LineEdit.terminal(s)
            REPL.raw!(terminal, false) && LineEdit.disable_bracketed_paste(terminal)
            LineEdit.mode(s).on_done(s, LineEdit.buffer(s), true)
            REPL.raw!(terminal, true) && LineEdit.enable_bracketed_paste(terminal)
        end
        oldpos = nextpos + 1
    end
    LineEdit.refresh_line(s)
end

mutable struct RCompletionProvider <: LineEdit.CompletionProvider
    r::REPL.LineEditREPL
end

function LineEdit.complete_line(c::RCompletionProvider, s)
    buf = s.input_buffer
    partial = String(buf.data[1:buf.ptr-1])
    # complete latex
    full = LineEdit.input_string(s)
    ret, range, should_complete = REPLCompletions.bslash_completions(full, endof(partial))[2]
    if length(ret) > 0 && should_complete
        return ret, partial[range], true
    end

    # complete r
    utils = findNamespace("utils")
    rcall_p(utils[".assignLinebuffer"], partial)
    rcall_p(utils[".assignEnd"], length(partial))
    token = rcopy(rcall_p(utils[".guessTokenFromLine"]))
    rcall_p(utils[".completeToken"])
    ret = rcopy(Array, rcall_p(utils[".retrieveCompletions"]))
    if length(ret) > 0
        return ret, token, true
    end

    return String[], 0:-1, false
end

function create_r_repl(repl, main)
    r_mode = LineEdit.Prompt("R> ";
        prompt_prefix=Base.text_colors[:blue],
        prompt_suffix=main.prompt_suffix,
        sticky=true)

    hp = main.hist
    hp.mode_mapping[:r] = r_mode
    r_mode.hist = hp
    r_mode.complete = RCompletionProvider(repl)
    r_mode.on_enter = (s) -> begin
        status = parse_status(String(LineEdit.buffer(s)))
        status == :ok || status == :error
    end
    r_mode.on_done = (s, buf, ok) -> begin
        if !ok
            return REPL.transition(s, :abort)
        end
        script = String(take!(buf))
        if !isempty(strip(script))
            REPL.reset(repl)
            try
                repl_eval(script, repl.t.out_stream, repl.t.err_stream)
            catch y
                # should never reach
                simple_showerror(stderr, y)
            end
        end
        REPL.prepare_next(repl)
        REPL.reset_state(s)
        s.current_mode.sticky || REPL.transition(s, main)
    end

    const bracketed_paste_mode_keymap = Dict{Any,Any}(
        "\e[200~" => bracketed_paste_callback
    )

    search_prompt, skeymap = LineEdit.setup_search_keymap(hp)
    prefix_prompt, prefix_keymap = LineEdit.setup_prefix_keymap(hp, r_mode)

    mk = REPL.mode_keymap(main)
    # ^C should not exit prompt
    delete!(mk, "^C")

    b = Dict{Any,Any}[
        bracketed_paste_mode_keymap,
        skeymap, mk, prefix_keymap, LineEdit.history_keymap,
        LineEdit.default_keymap, LineEdit.escape_defaults
    ]
    r_mode.keymap_dict = LineEdit.keymap(b)

    r_mode
end

function repl_init(repl)
    mirepl = isdefined(repl,:mi) ? repl.mi : repl
    main_mode = mirepl.interface.modes[1]
    r_mode = create_r_repl(mirepl, main_mode)
    push!(mirepl.interface.modes,r_mode)

    const r_prompt_keymap = Dict{Any,Any}(
        '$' => function (s,args...)
            if isempty(s) || position(LineEdit.buffer(s)) == 0
                buf = copy(LineEdit.buffer(s))
                LineEdit.transition(s, r_mode) do
                    LineEdit.state(s, r_mode).input_buffer = buf
                end
            else
                LineEdit.edit_insert(s, '$')
            end
        end
    )

    main_mode.keymap_dict = LineEdit.keymap_merge(main_mode.keymap_dict, r_prompt_keymap);
    nothing
end

function repl_inited(repl)
    mirepl = isdefined(repl,:mi) ? repl.mi : repl
    any(:prompt in fieldnames(typeof(m)) && m.prompt == "R> " for m in mirepl.interface.modes)
end

end # module
