import Base: REPL, LineEdit

function return_callback(s)
    st = sexp(String(LineEdit.buffer(s)))
    protect(st)
    status = Array(Cint,1)
    expr = ccall((:R_ParseVector,libR),UnknownSxpPtr,
                (Ptr{StrSxp},Cint,Ptr{Cint},UnknownSxpPtr),
                st,-1,status,sexp(Const.NilValue))
    unprotect(1)
    return status[1] == 1 || status[1] >= 3
end

function evaluate_callback(line)
    st = sexp(line)
    protect(st)
    status = Array(Cint,1)
    expr = ccall((:R_ParseVector,libR),UnknownSxpPtr,
                (Ptr{StrSxp},Cint,Ptr{Cint},UnknownSxpPtr),
                st,-1,status,sexp(Const.NilValue))
    unprotect(1)
    s = status[1]
    if s != 1
        msg = Compat.unsafe_string(cglobal((:R_ParseErrorMsg, libR), UInt8))
        print(STDERR, "Error: $msg")
        return nothing
    end
    expr = sexp(expr)
    protect(expr)
    err = Array(Cint,1)
    local val
    for e in expr
        val = ccall((:R_tryEval,libR),UnknownSxpPtr,
            (UnknownSxpPtr,Ptr{EnvSxp},Ptr{Cint}),e,sexp(Const.GlobalEnv),err)
        if nb_available(printBuffer) != 0
            print(STDOUT, takebuf_string(printBuffer))
        end
    end
    unprotect(1)
    if err[1] !=0 || nb_available(errorBuffer) != 0
        print(STDERR, takebuf_string(errorBuffer))
    end
    # print if the last expression is visible
    R_Visible = unsafe_load(cglobal((:R_Visible, libR),Int))
    err[1] == 0 && R_Visible == 1 && rprint(STDOUT, sexp(val))
    return nothing
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

function repl_init()
    repl = Base.active_repl
    mirepl = isdefined(repl,:mi) ? repl.mi : repl

    main_mode = mirepl.interface.modes[1]

    panel = LineEdit.Prompt("R> ";
        prompt_prefix=Base.text_colors[:blue],
        prompt_suffix=main_mode.prompt_suffix,
        on_enter=return_callback)

    hp = main_mode.hist
    hp.mode_mapping[:r] = panel
    panel.hist = hp
    panel.on_done = REPL.respond(evaluate_callback, repl,panel; pass_empty = false)
    panel.complete = RCompletionProvider(repl)


    push!(mirepl.interface.modes,panel)

    const rcall_keymap = Dict{Any,Any}(
        '$' => function (s,args...)
            if isempty(s)
                if !haskey(s.mode_state,panel)
                    s.mode_state[panel] = LineEdit.init_state(repl.t,panel)
                end
                LineEdit.transition(s,panel)
            else
                LineEdit.edit_insert(s,'$')
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
