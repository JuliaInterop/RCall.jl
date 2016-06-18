import Base: REPL, LineEdit

function repl_init()
    repl = Base.active_repl
    mirepl = isdefined(repl,:mi) ? repl.mi : repl

    main_mode = mirepl.interface.modes[1]

    panel = LineEdit.Prompt("R> ";
        prompt_prefix=Base.text_colors[:blue],
        prompt_suffix=main_mode.prompt_suffix)

    hp = main_mode.hist
    hp.mode_mapping[:r] = panel
    panel.hist = hp

    panel.on_done = REPL.respond(repl,panel; pass_empty = false) do line
        st = sexp(line)
        protect(st)
        status = Array(Cint,1)
        expr = ccall((:R_ParseVector,libR),UnknownSxpPtr,
                    (Ptr{StrSxp},Cint,Ptr{Cint},UnknownSxpPtr),
                    st,-1,status,sexp(Const.NilValue))
        unprotect(1)
        s = status[1]
        if s != 1
            s == 2 && print(STDOUT, "Incomplete R expression.")
            s == 3 && print(STDOUT, "Invalid R expression.")
            s == 4 && print(STDOUT, "Parse Error.")
            return nothing
        end
        expr = sexp(expr)
        protect(expr)
        err = Array(Cint,1)
        local val
        for e in expr
            val = ccall((:R_tryEval,libR),UnknownSxpPtr,
                (UnknownSxpPtr,Ptr{EnvSxp},Ptr{Cint}),e,sexp(Const.GlobalEnv),err)
        end
        unprotect(1)
        if err[1] !=0 || nb_available(errorBuffer) != 0
            print(STDERR, Compat.readstring(errorBuffer))
        end
        # print if the last expression is visible
        R_Visible = unsafe_load(cglobal((:R_Visible, libR),Int))
        err[1] == 0 && R_Visible == 1 && rprint(STDOUT, sexp(val))
        return nothing
    end

    push!(mirepl.interface.modes,panel)

    const rcall_keymap = Dict{Any,Any}(
        '<' => function (s,args...)
            if isempty(s)
                if !haskey(s.mode_state,panel)
                    s.mode_state[panel] = LineEdit.init_state(repl.t,panel)
                end
                LineEdit.transition(s,panel)
            else
                LineEdit.edit_insert(s,'<')
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
