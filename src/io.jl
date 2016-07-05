"Print the value of an Sxp using R's printing mechanism"
function rprint{S<:Sxp}(io::IO, s::Ptr{S})
    global PrintBufferLocked
    PrintBufferLocked = true
    protect(s)
    # Rf_PrintValue can cause segfault if S3 objects has custom
    # print function as it doesn't use R_tryEval
    # ccall((:Rf_PrintValue,libR),Void,(Ptr{S},),s)
    # below mirrors Rf_PrintValue
    env = protect(newEnvironment(Const.GlobalEnv))
    env[:x] = s
    if isObject(s) || isFunction(s)
        if isS4(s)
            methodsNamespace = protect(findNamespace("methods"))
            tryEval(rlang_p(methodsNamespace[:show], :x), env)
            unprotect(1)
        else
            tryEval(rlang_p(Const.BaseNamespace[:print], :x) ,env)
        end
    else
        # Rf_PrintValueRec not found on unix!?
        # ccall((:Rf_PrintValueRec,libR),Void,(Ptr{S},Ptr{EnvSxp}),s, Const.GlobalEnv)
        tryEval(rlang_p(Const.BaseNamespace[Symbol("print.default")], :x), env)
    end
    env[:x] = Const.NilValue
    write(io,takebuf_string(printBuffer))

    # in general, only S3/S4 custom print will fail
    if nb_available(errorBuffer) != 0
        warn(takebuf_string(errorBuffer))
    end
    unprotect(2)
    PrintBufferLocked = false
    nothing
end
rprint(io::IO,r::RObject) = rprint(io,r.p)
rprint(s) = rprint(STDOUT,s)

"""
Parse, evaluate and print the result of a string as an R expression.
"""
rprint(io::IO,str::Compat.String) = rprint(io,reval(str))
rprint(io::IO,sym::Symbol) = rprint(io,reval(sym))


function show(io::IO,r::RObject)
    println(io,typeof(r))
    rprint(io,r.p)
    # ggplot2's plot is displayed after `print` function is invoked,
    # so we have to clear any displayed plots.
    isdefined(Main, :IJulia) && Main.IJulia.inited && ijulia_displayplots()
end

function display_error(io::IO, er)
    Base.with_output_color(:red, io) do io
        print(io, "ERROR: ")
        Base.showerror(io, er)
        println(io)
    end
end

global const printBuffer = PipeBuffer()
global const errorBuffer = PipeBuffer()

function write_console_ex(buf::Ptr{UInt8},buflen::Cint,otype::Cint)
    if otype == 0
        Compat.unsafe_write(printBuffer, buf, buflen)
    else
        Compat.unsafe_write(errorBuffer, buf, buflen)
    end
    return nothing
end

# mainly use to prevent flush_print_buffer stealing rprint output
global PrintBufferLocked = false

function flush_print_buffer(io::IO)
    global PrintBufferLocked
    # dump printBuffer's content when it is not locked
    if ! PrintBufferLocked
        nb_available(printBuffer) != 0  && write(io, takebuf_string(printBuffer))
    end
    nothing
end
