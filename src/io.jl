"Print the value of an Sxp using R's printing mechanism"
function rprint{S<:Sxp}(s::Ptr{S}; stdout::IO=STDOUT, stderr::IO=error_device)
    protect(s)
    # Rf_PrintValue can cause segfault if a S3/S4 object has custom
    # print function as it doesn't use R_tryEval
    # below mirrors Rf_PrintValue
    env = protect(newEnvironment(Const.GlobalEnv))
    defineVar(:x, s, env)
    lock_output()
    if isObject(s) || isFunction(s)
        if isS4(s)
            _, status = tryEval(rlang_p(findNamespace("methods")[:show], :x), env)
        else
            _, status = tryEval(rlang_p(Const.BaseNamespace[:print], :x) ,env)
        end
    else
        # Rf_PrintValueRec not found on unix!?
        # ccall((:Rf_PrintValueRec,libR),Void,(Ptr{S},Ptr{EnvSxp}),s, Const.GlobalEnv)
        _, status = tryEval(rlang_p(Const.BaseNamespace[Symbol("print.default")], :x), env)
    end
    defineVar(:x, Const.NilValue, env)
    try
        flush_output(stdout, force=true)
        flush_error(stderr, is_warning = status == 0)
    finally
        unlock_output()
        unprotect(2)
    end
    # ggplot2's plot is displayed after `print` function is invoked,
    # so we have to clear any displayed plots.
    isdefined(Main, :IJulia) && Main.IJulia.inited && ijulia_displayplots()
    nothing
end
rprint(r::RObject; stdout::IO=STDOUT, stderr::IO=error_device) = rprint(r.p, stdout=stdout, stderr=stderr)

function show(io::IO,r::RObject)
    println(io, typeof(r))
    rprint(r, stdout=io)
end

function simple_showerror(io::IO, er)
    Base.with_output_color(:red, io) do io
        print(io, "ERROR: ")
        showerror(io, er)
        println(io)
    end
end

mutable struct REvalutionError <: Exception
    msg::AbstractString
    REvalutionError() = new("")
    # R error messages may have trailing "\n"
    REvalutionError(msg::AbstractString) = new(rstrip(msg))
end

showerror(io::IO, e::REvalutionError) = print(io, e.msg)
showerror(io::IO, e::REvalutionError, bt; backtrace=false) = showerror(io ,e)
