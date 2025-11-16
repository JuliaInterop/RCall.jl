module RPrompt

using REPL
import REPL: REPL, LineEdit, REPLCompletions
import ..REvalError
import ..Const
import ..RCall:
    libR,
    rparse_p,
    reval_p,
    reval,
    findNamespace,
    getNamespace,
    rcall,
    rlang,
    rlang_p,
    rcall_p,
    rprint,
    rcopy,
    render,
    sexp,
    protect,
    unprotect,
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

    return nothing
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
    return status
end

function repl_eval(script::String, stdout::IO, stderr::IO)
    local nprotect = 0
    try
        script, symdict = render(script)
        if length(symdict) > 0
            Core.eval(Main, prepare_inline_julia_code(symdict))
        end
        # the newlines are important in case script has a trailing inline comment
        ret = protect(reval_p(rparse_p("withVisible({\n$script\n})"), Const.GlobalEnv.p))
        nprotect += 1
        # print if the last expression is visible
        if rcopy(Bool, ret[:visible])
             rprint(stdout, ret[:value])
        end
    catch ex
        if isa(ex, REvalError)
            println(stderr, ex.msg)
        elseif isa(ex, RParseIncomplete) || isa(ex, RParseError)  || isa(ex, RParseEOF)
            println(stderr, ex.msg)
        else
            simple_showerror(stderr, ex)
        end
    finally
        unprotect(nprotect)
        return nothing
    end
end

@static if isdefined(LineEdit, :check_show_hints)
    refresh_line_(s) = LineEdit.check_show_hint(s)
else
    refresh_line_(s) = LineEdit.refresh_line(s)
end

function bracketed_paste_callback(s, o...)
    input = LineEdit.bracketed_paste(s)
    sbuffer = LineEdit.buffer(s)
    curspos = position(sbuffer)
    seek(sbuffer, 0)
    shouldeval = (bytesavailable(sbuffer) == curspos && !occursin(UInt8('\n'), sbuffer))
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

    m = sizeof(input)
    oldpos = 1
    nextpos = 0
    # parse the input line by line
    while nextpos < m
        next_result = findnext("\n", input, nextpos + 1)
        if isnothing(next_result)
            nextpos = m
        else
            nextpos = next_result[1]
        end
        block = input[oldpos:nextpos]
        status = parse_status(block)

        if status == :error  || (status == :incomplete && nextpos == m) ||
                (nextpos == m && !endswith(input, '\n'))
            # error / continue and the end / at the end but no new line
            LineEdit.replace_line(s, input[oldpos:end])
            refresh_line_(s)
            break
        elseif status == :incomplete && nextpos < m
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
    refresh_line_(s)
end

struct RCompletionProvider <: LineEdit.CompletionProvider
    repl::REPL.LineEditREPL
    line_modify_lock::ReentrantLock
    hint_generation_lock::ReentrantLock
    function RCompletionProvider(repl::REPL.LineEditREPL)
        repl.mistate = @something(repl.mistate, LineEdit.init_state(REPL.terminal(repl), repl.interface))
        @static if hasfield(LineEdit.MIState, :hint_generation_lock)
            hint_generation_lock = repl.mistate.hint_generation_lock
        else
            hint_generation_lock = ReentrantLock()
        end
        @static if hasfield(LineEdit.MIState, :line_modify_lock)
            line_modify_lock = repl.mistate.line_modify_lock
        else
            line_modify_lock = ReentrantLock()
        end

        return new(repl, hint_generation_lock, line_modify_lock)
    end
end

# Julia PR #54311 (backported to 1.11) added the `hint` argument
if v"1.11.0-beta1.46" <= VERSION < v"1.12.0-DEV.0" || VERSION >= v"1.12.0-DEV.468"
    using REPL.REPLCompletions: bslash_completions
else
    function bslash_completions(string::String, pos::Int, hint::Bool=false)
        return REPLCompletions.bslash_completions(string, pos)
    end
end

# Julia PR 54800 messed up REPL completion, fix adapted from https://github.com/JuliaLang/IJulia.jl/pull/1147
if isdefined(REPLCompletions, :named_completion) # julia#54800 (julia 1.12)
    completion_text_(c) = REPLCompletions.named_completion(c).completion::String
else
    completion_text_(c) = REPLCompletions.completion_text(c)
end

function LineEdit.complete_line(c::RCompletionProvider, s; hint::Bool=false)
    reval("library(utils)")
    @lock c.hint_generation_lock begin
        buf = s.input_buffer
        partial = String(take!(copy(buf))) # String(buf.data[1:buf.ptr-1])
        # complete latex
        full = LineEdit.input_string(s)
        ret, range, should_complete = bslash_completions(full, lastindex(partial), hint)[2]
        if length(ret) > 0 && should_complete
            return map(completion_text_, ret), partial[range], should_complete
        end

        # complete r
        # XXX As of Julia 1.12, this happens on a background thread
        # and findNamespace + function pointers seems to be unsafe in that context, so we must
        # use the slightly slower explicit language

        rcall_p(reval("utils:::.assignLinebuffer"), partial)
        rcall_p(reval("utils:::.assignEnd"), length(partial))
        token = rcopy(reval("utils:::.guessTokenFromLine()"))
        reval("utils:::.completeToken()")
        ret = rcopy(Vector{String}, reval("utils:::.retrieveCompletions()"))::Vector{String}

        # faster way that doesn't seem to play nice with testing on Julia 1.12
        # utils = findNamespace("utils")
        # rcall_p(utils[".assignLinebuffer"], partial)
        # rcall_p(utils[".assignEnd"], length(partial))
        # token = rcopy(rcall_p(utils[".guessTokenFromLine"]))
        # rcall_p(utils[".completeToken"])
        # ret = rcopy(Array, rcall_p(utils[".retrieveCompletions"]))

        if length(ret) > 0
            return ret, token, true
        end

        return String[], "", false
    end
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
        status = parse_status(String(take!(copy(LineEdit.buffer(s)))))
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
                simple_showerror(repl.t.err_stream, y)
            end
        end
        REPL.prepare_next(repl)
        REPL.reset_state(s)
        s.current_mode.sticky || REPL.transition(s, main)
    end

    bracketed_paste_mode_keymap = Dict{Any,Any}(
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
    if !isdefined(repl, :interface)
        repl.interface = REPL.setup_interface(repl)
    end
    interface = repl.interface
    main_mode = interface.modes[1]
    r_mode = create_r_repl(repl, main_mode)
    push!(repl.interface.modes,r_mode)

    r_prompt_keymap = Dict{Any,Any}(
        '$' => function (s, args...)
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
    return nothing
end

function repl_inited(repl)
    interface = repl.interface

    return any(:prompt in fieldnames(typeof(m)) && m.prompt == "R> " for m in interface.modes)
end

end # module
