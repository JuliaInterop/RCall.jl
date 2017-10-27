# used in flush_output and flush_error
struct ErrorIO <: IO end
const error_device = ErrorIO()


# mainly use to prevent flush_output stealing rprint output
_output_is_locked = false

const output_buffer_ = PipeBuffer()
const error_buffer = PipeBuffer()


"Print the value of an Sxp using R's printing mechanism"
function rprint(s::Ptr{S}; stdout::IO=STDOUT, stderr::IO=error_device) where S<:Sxp
    global _output_is_locked
    protect(s)
    # Rf_PrintValue can cause segfault if a S3/S4 object has custom
    # print function as it doesn't use R_tryEval
    # below mirrors Rf_PrintValue
    env = protect(newEnvironment(Const.GlobalEnv))
    defineVar(:x, s, env)
    _output_is_locked = true
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
        _output_is_locked = false
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


"""
R API callback to write console output.
"""
function write_console_ex(buf::Ptr{UInt8},buflen::Cint,otype::Cint)
    if otype == 0
        unsafe_write(output_buffer_, buf, buflen)
    else
        unsafe_write(error_buffer, buf, buflen)
    end
    return nothing
end

function flush_output(io::IO; force::Bool=false)
    # dump output_buffer_'s content when it is not locked
    if (!_output_is_locked || force) && nb_available(output_buffer_) != 0
        write(io, String(take!(output_buffer_)))
    end
    nothing
end

function flush_error(io::IO; is_warning::Bool=false)
    if nb_available(error_buffer) != 0
        write(io, String(take!(error_buffer)))
    end
    nothing
end

function flush_error(io::ErrorIO; is_warning::Bool=false)
    if nb_available(error_buffer) != 0
        s = String(take!(error_buffer))
        if is_warning
            warn("RCall.jl: ", s)
        else
            throw(REvalutionError("RCall.jl: " * s))
        end
    end
    nothing
end
