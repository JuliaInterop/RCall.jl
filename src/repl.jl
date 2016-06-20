import Base: REPL, LineEdit

global REPL_STDOUT
global REPL_STDERR

function return_callback(s)
    st = protect(sexp(Compat.String(LineEdit.buffer(s))))
    status = ParseVector(st)[2]
    unprotect(1)
    status == 1 || status >= 3
end

function evaluate_callback(line)
    global REPL_STDOUT
    global REPL_STDERR
    local status
    local val

    st = protect(sexp(line))
    expr, status, msg = ParseVector(st)
    unprotect(1)
    if status != 1
        write(REPL_STDERR, "Error: $msg\n")
        return nothing
    end
    expr = protect(sexp(expr))
    for e in expr
        val, status = tryEval(e, sexp(Const.GlobalEnv))
        flush_printBuffer(REPL_STDOUT)
        # print warning and error messages
        if status != 0 || nb_available(errorBuffer) != 0
            write(REPL_STDERR, takebuf_string(errorBuffer))
        end
        status != 0 && return nothing
    end
    unprotect(1)
    # print if the last expression is visible
    if status == 0 && unsafe_load(cglobal((:R_Visible, libR),Int)) == 1
         rprint(REPL_STDOUT, sexp(val))
    end
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

function repl_init(repl)
    global REPL_STDOUT
    global REPL_STDERR
    REPL_STDOUT = repl.t.out_stream
    REPL_STDERR = repl.t.err_stream

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
