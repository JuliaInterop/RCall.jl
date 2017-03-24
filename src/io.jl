"Print the value of an Sxp using R's printing mechanism"
function rprint{S<:Sxp}(io::IO, s::Ptr{S})
    Console.lock_output()
    protect(s)
    # Rf_PrintValue can cause segfault if a S3/S4 object has custom
    # print function as it doesn't use R_tryEval
    # below mirrors Rf_PrintValue
    env = protect(newEnvironment(Const.GlobalEnv))
    env[:x] = s
    if isObject(s) || isFunction(s)
        if isS4(s)
            tryEval(rlang_p(findNamespace("methods")[:show], :x), env)
        else
            tryEval(rlang_p(Const.BaseNamespace[:print], :x) ,env)
        end
    else
        # Rf_PrintValueRec not found on unix!?
        # ccall((:Rf_PrintValueRec,libR),Void,(Ptr{S},Ptr{EnvSxp}),s, Const.GlobalEnv)
        tryEval(rlang_p(Const.BaseNamespace[Symbol("print.default")], :x), env)
    end
    env[:x] = Const.NilValue
    Console.write_output(io, force=true)
    unprotect(2)
    Console.unlock_output()
    # ggplot2's plot is displayed after `print` function is invoked,
    # so we have to clear any displayed plots.
    isdefined(Main, :IJulia) && Main.IJulia.inited && IJuliaHooks.ijulia_displayplots()
    nothing
end
rprint(io::IO,r::RObject) = rprint(io,r.p)
rprint(s) = rprint(STDOUT,s)

function show(io::IO,r::RObject)
    println(io,typeof(r))
    rprint(io,r.p)
    # print error messages or warnings
    # in general, only S3/S4 custom print will fail
    Console.write_error(Console.error_device)
end

function simple_showerror(io::IO, er)
    Base.with_output_color(:red, io) do io
        print(io, "ERROR: ")
        Base.showerror(io, er)
        println(io)
    end
end

type REvalutionError <: Exception
    msg::AbstractString
    REvalutionError() = new("")
    REvalutionError(msg::AbstractString) = new(msg)
end

Base.showerror(io::IO, e::REvalutionError, bt; backtrace=false) = print(io, e.msg)
