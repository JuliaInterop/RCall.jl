"Print the value of an Sxp using R's printing mechanism"
function rprint{S<:Sxp}(devices::Tuple{IO,IO,IO}, s::Ptr{S})
    stdio, warningio, errorio = devices
    protect(s)
    # Rf_PrintValue can cause segfault if a S3/S4 object has custom
    # print function as it doesn't use R_tryEval
    # below mirrors Rf_PrintValue
    env = protect(newEnvironment(Const.GlobalEnv))
    env[:x] = s
    Console.lock_output()
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
    env[:x] = Const.NilValue
    try
        if status != 0
            Console.write_error(errorio)
        else
            Console.write_output(stdio, force=true)
            Console.write_error(warningio)
        end
    finally
        Console.unlock_output()
        unprotect(2)
    end
    # ggplot2's plot is displayed after `print` function is invoked,
    # so we have to clear any displayed plots.
    isdefined(Main, :IJulia) && Main.IJulia.inited && IJuliaHooks.ijulia_displayplots()
    nothing
end
rprint{S<:Sxp}(io::IO, s::Ptr{S}) = rprint((io, Console.warning_device, Console.error_device), s)
rprint(io::IO, r::RObject) = rprint(io ,r.p)
rprint(s) = rprint(STDOUT,s)

function show(io::IO,r::RObject)
    println(io, typeof(r))
    rprint(io, r)
end

function simple_showerror(io::IO, er)
    Base.with_output_color(:red, io) do io
        print(io, "ERROR: ")
        showerror(io, er)
        println(io)
    end
end

type REvalutionError <: Exception
    msg::AbstractString
    REvalutionError() = new("")
    # R error messages may have trailing "\n"
    REvalutionError(msg::AbstractString) = new(rstrip(msg))
end

showerror(io::IO, e::REvalutionError) = print(io, e.msg)
showerror(io::IO, e::REvalutionError, bt; backtrace=false) = showerror(io ,e)


# used in write_output and write_error
type WarningIO <: IO end
type ErrorIO <: IO end

write(io::WarningIO, s::String) = warn("RCall.jl: ", s)
write(io::ErrorIO, s::String) = throw(REvalutionError("RCall.jl: " * s))
