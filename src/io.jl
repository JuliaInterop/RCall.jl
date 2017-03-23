"Print the value of an Sxp using R's printing mechanism"
function rprint{S<:Sxp}(io::IO, s::Ptr{S})
    lock_output()
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
    console_write_output(io, force=true)
    unprotect(2)
    unlock_output()
    # ggplot2's plot is displayed after `print` function is invoked,
    # so we have to clear any displayed plots.
    isdefined(Main, :IJulia) && Main.IJulia.inited && ijulia_displayplots()
    nothing
end
rprint(io::IO,r::RObject) = rprint(io,r.p)
rprint(s) = rprint(STDOUT,s)

function show(io::IO,r::RObject)
    println(io,typeof(r))
    rprint(io,r.p)
    # print error messages or warnings
    # in general, only S3/S4 custom print will fail
    console_write_error(io)
end

function display_error(io::IO, er)
    Base.with_output_color(:red, io) do io
        print(io, "ERROR: ")
        Base.showerror(io, er)
        println(io)
    end
end

let
    local const output_buffer_ = PipeBuffer()
    local const error_buffer = PipeBuffer()
    # mainly use to prevent console_write_output stealing rprint output
    local output_is_locked = false

    global function write_console_ex(buf::Ptr{UInt8},buflen::Cint,otype::Cint)
        if otype == 0
            unsafe_write(output_buffer_, buf, buflen)
        else
            unsafe_write(error_buffer, buf, buflen)
        end
        return nothing
    end

    global function console_write_output(io::IO; force::Bool=false)
        # dump output_buffer_'s content when it is not locked
        if (!output_is_locked || force) && nb_available(output_buffer_) != 0
            write(io, String(take!(output_buffer_)))
        end
        nothing
    end

    global function console_write_error(io::IO)
        if nb_available(error_buffer) != 0
            write(io, String(take!(error_buffer)))
        end
        nothing
    end

    global function console_throw_error(as_error::Bool=true)
        if nb_available(error_buffer) != 0
            if as_error
                error("RCall.jl: ", String(take!(error_buffer)))
            else
                warn("RCall.jl: ", String(take!(error_buffer)))
            end
        end
    end

    global function lock_output()
        output_is_locked = true
    end

    global function unlock_output()
        output_is_locked = false
    end
end
