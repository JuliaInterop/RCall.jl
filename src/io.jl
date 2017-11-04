# mainly use to prevent display_eval_output stealing rprint output
_output_is_locked = false

const output_buffer = PipeBuffer()
const error_buffer = PipeBuffer()


"Print the value of an Sxp using R's printing mechanism"
function rprint(io::IO, s::Ptr{S}) where S<:Sxp
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
        handle_eval_stdout(status, io=io, force=true)
        handle_eval_stderr(status)
    finally
        _output_is_locked = false
        unprotect(2)
    end
    # ggplot2's plot is displayed after `print` function is invoked,
    # so we have to clear any displayed plots.
    isdefined(Main, :IJulia) && Main.IJulia.inited && ijulia_displayplots()
    nothing
end
rprint(io::IO, r::RObject) = rprint(io::IO, r.p)
rprint(r::RObject) = rprint(STDOUT, r)

function show(io::IO,r::RObject)
    println(io, typeof(r))
    rprint(io, r)
end


abstract type RException <: Exception end
showerror(io::IO, e::RException, bt; backtrace=false) = showerror(io ,e)

# status = 2
struct RParseIncomplete <: RException
    msg::AbstractString
    RParseIncomplete(msg::AbstractString) = new(rstrip(msg))
end
showerror(io::IO, e::RParseIncomplete) = print(io, "RParseIncomplete: " * e.msg)

# status = 3
struct RParseError <: RException
    msg::AbstractString
    RParseError() = new("")
    RParseError(msg::AbstractString) = new(rstrip(msg))
end
showerror(io::IO, e::RParseError) = print(io, "RParseError: " * e.msg)

# status = 4
struct RParseEOF <: RException
    msg::AbstractString
    RParseEOF() = new("read end of file")
    RParseEOF(msg::AbstractString) = new(rstrip(msg))
end
showerror(io::IO, e::RParseEOF) = print(io, "RParseEOF: " * e.msg)


struct REvalError <: RException
    msg::AbstractString
    REvalError() = new("")
    REvalError(msg::AbstractString) = new(rstrip(msg))
end
showerror(io::IO, e::REvalError) = print(io, "REvalError: " * e.msg)


"""
R API callback to write console output.
"""
function write_console_ex(buf::Ptr{UInt8},buflen::Cint,otype::Cint)
    if otype == 0
        unsafe_write(output_buffer, buf, buflen)
    else
        unsafe_write(error_buffer, buf, buflen)
    end
    return nothing
end

function handle_eval_stdout(status::Integer; io::IO=STDOUT, force::Bool=false)
    if (!_output_is_locked || force) && nb_available(output_buffer) != 0
        write(io, String(take!(output_buffer)))
    end
end

function handle_eval_stderr(status::Integer)
    if nb_available(error_buffer) != 0
        s = String(take!(error_buffer))
        if status == 0
            warn("RCall.jl: ", s)
        else
            throw(REvalError(s))
        end
    end
end
