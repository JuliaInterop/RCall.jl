import Base: LineEdit, REPL, REPLCompletions

function return_callback(s)
    status = render(Compat.String(LineEdit.buffer(s)))[3]
    status == 1 || status >= 3
end

function generate_inline_julia_code(symdict::OrderedDict)
    blk_ld = Expr(:block)
    for (rsym, expr) in symdict
        push!(blk_ld.args,:(env[$rsym] = $(expr)))
    end
    quote
        let env = RCall.reval_p(RCall.rparse_p("`#JL` <- new.env()"))
            $blk_ld
            nothing
        end
    end
end

function repl_eval(script::Compat.String, stdout::IO, stderr::IO)
    local status
    local val
    script, symdict, status, msg = render(script)
    if status != 1
        write(stderr, "Error: $msg\n")
        return nothing
    end
    try
        if length(symdict) > 0
            eval(Main, generate_inline_julia_code(symdict))
        end
        expr = protect(sexp(parseVector(sexp(script))[1]))
        for e in expr
            val, status = tryEval(e, sexp(Const.GlobalEnv))
            flush_print_buffer(stdout)
            # print warning and error messages
            if status != 0 || nb_available(errorBuffer) != 0
                write(stderr, takebuf_string(errorBuffer))
            end
            status != 0 && return nothing
        end
    catch e
        display_error(stderr, e)
        return nothing
    finally
        unprotect(1)
    end
    # print if the last expression is visible
    if status == 0 && unsafe_load(cglobal((:R_Visible, libR),Int)) == 1
         rprint(stdout, sexp(val))
    end
    return nothing
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
    input = takebuf_string(sbuffer)

    oldpos = start(input)
    nextpos = 0
    # parse the input line by line
    while !done(input, oldpos)
        nextpos = search(input, '\n', nextpos+1)
        if nextpos == 0
            nextpos = endof(input)
        end
        block = input[oldpos:nextpos]
        status = render(block)[3]

        if status >= 3  || (status == 2 && done(input, nextpos+1)) ||
                (done(input, nextpos+1) && !endswith(input, '\n'))
            # error / continue but no the end / at the end but no new line
            LineEdit.replace_line(s, input[oldpos:end])
            LineEdit.refresh_line(s)
            break
        elseif status == 2 && !done(input, nextpos+1)
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

function respond(repl, main)
    (s, buf, ok) -> begin
        if !ok
            return REPL.transition(s, :abort)
        end
        script = takebuf_string(buf)
        if !isempty(strip(script))
            REPL.reset(repl)
            repl_eval(script, repl.t.out_stream, repl.t.err_stream)
        end
        REPL.prepare_next(repl)
        REPL.reset_state(s)
        s.current_mode.sticky || REPL.transition(s, main)
    end
end

type RCompletionProvider <: LineEdit.CompletionProvider
    r::REPL.LineEditREPL
end

function LineEdit.complete_line(c::RCompletionProvider, s)
    buf = s.input_buffer
    partial = Compat.String(buf.data[1:buf.ptr-1])
    # complete latex
    full = LineEdit.input_string(s)
    ret, range, should_complete = REPLCompletions.bslash_completions(full, endof(partial))[2]
    if length(ret) > 0 && should_complete
        return ret, partial[range], true
    end

    # complete r
    rcall(rlang(Symbol(":::"), :utils, Symbol(".assignLinebuffer")), partial)
    rcall(rlang(Symbol(":::"), :utils, Symbol(".assignEnd")), length(partial))
    token = rcopy(rcall(rlang(Symbol(":::"), :utils, Symbol(".guessTokenFromLine"))))
    rcall(rlang(Symbol(":::"), :utils, Symbol(".completeToken")))
    ret = rcopy(Array, rcall(rlang(Symbol(":::"), :utils, Symbol(".retrieveCompletions"))))
    if length(ret) > 0
        return ret, token, true
    end

    return Compat.String[], 0:-1, false
end

function create_r_repl(repl, main)
    r_mode = LineEdit.Prompt("R> ";
        prompt_prefix=Base.text_colors[:blue],
        prompt_suffix=main.prompt_suffix,
        on_enter=return_callback,
        on_done= respond(repl, main),
        sticky=true)

    hp = main.hist
    hp.mode_mapping[:r] = r_mode
    r_mode.hist = hp
    r_mode.complete = RCompletionProvider(repl)
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
