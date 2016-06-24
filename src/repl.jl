import Base: REPL, LineEdit

function return_callback(s)
    _, _, status, _ = render_rscript(Compat.String(LineEdit.buffer(s)))
    status == 1 || status >= 3
end

function eval_user_input(script::Compat.String, stdout::IO, stderr::IO)
    local status
    local val
    script, symdict, status, msg = render_rscript(script)
    if status != 1
        write(stderr, "Error: $msg\n")
        return nothing
    end
    blk_ld = Expr(:block)
    for (rsym, expr) in symdict
        push!(blk_ld.args,:(env[$rsym] = $(expr)))
    end
    jscript = quote
        let env = RCall.protect(RCall.newEnvironment())
            globalEnv["#JL"] = env
            try
                $blk_ld
            finally
                RCall.unprotect(1)
            end
            nothing
        end
    end

    try
        eval(Main, jscript)
    catch e
        display_error(stderr, e)
        return nothing
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
    unprotect(1)
    # print if the last expression is visible
    if status == 0 && unsafe_load(cglobal((:R_Visible, libR),Int)) == 1
         rprint(stdout, sexp(val))
    end
    return nothing
end

function respond(repl, main)
    (s, buf, ok) -> begin
        if !ok
            return REPL.transition(s, :abort)
        end
        script = takebuf_string(buf)
        if !isempty(script)
            REPL.reset(repl)
            eval_user_input(script, repl.t.out_stream, repl.t.err_stream)
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
    rcall(rlang(symbol(":::"), :utils, symbol(".assignLinebuffer")), partial)
    rcall(rlang(symbol(":::"), :utils, symbol(".assignEnd")), length(partial))
    token = rcopy(rcall(rlang(symbol(":::"), :utils, symbol(".guessTokenFromLine"))))
    rcall(rlang(symbol(":::"), :utils, symbol(".completeToken")))
    ret = rcopy(Array, rcall(rlang(symbol(":::"), :utils, symbol(".retrieveCompletions"))))
    if length(ret) > 0
        return ret, token, true
    else
        return Compat.String[], 0:-1, false
    end
end

function repl_init(repl)
    mirepl = isdefined(repl,:mi) ? repl.mi : repl

    main_mode = mirepl.interface.modes[1]

    panel = LineEdit.Prompt("R> ";
        prompt_prefix=Base.text_colors[:blue],
        prompt_suffix=main_mode.prompt_suffix,
        on_enter=return_callback,
        on_done= respond(repl, main_mode),
        sticky=true)

    hp = main_mode.hist
    hp.mode_mapping[:r] = panel
    panel.hist = hp
    panel.complete = RCompletionProvider(repl)

    push!(mirepl.interface.modes,panel)

    const rcall_keymap = Dict{Any,Any}(
        '$' => function (s,args...)
            if isempty(s) || position(LineEdit.buffer(s)) == 0
                buf = copy(LineEdit.buffer(s))
                LineEdit.transition(s, panel) do
                    LineEdit.state(s, panel).input_buffer = buf
                end
            else
                LineEdit.edit_insert(s, '$')
            end
        end
    )

    search_prompt, skeymap = LineEdit.setup_search_keymap(hp)
    mk = REPL.mode_keymap(main_mode)

    b = Dict{Any,Any}[skeymap, mk, LineEdit.history_keymap, LineEdit.default_keymap, LineEdit.escape_defaults]
    panel.keymap_dict = LineEdit.keymap(b)

    main_mode.keymap_dict = LineEdit.keymap_merge(main_mode.keymap_dict, rcall_keymap);
    nothing
end
