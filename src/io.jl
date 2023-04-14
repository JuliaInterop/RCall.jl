# mainly use to prevent display_eval_output stealing rprint output
_output_is_locked = false

const output_buffer = PipeBuffer()
const error_buffer = PipeBuffer()


"Print the value of an Sxp using R's printing mechanism"
function rprint(io::IO, s::Ptr{S}) where S<:Sxp
    global _output_is_locked
    if s == C_NULL
        return
    end
    protect(s)
    # Rf_PrintValue can cause segfault if a S3/S4 object has custom
    # print function as it doesn't use R_tryEval
    # below mirrors Rf_PrintValue
    env = protect(newEnvironment(Const.GlobalEnv))
    defineVar(:x, s, env)
    _output_is_locked = true
    status = Ref{Cint}()
    if isObject(s) || isFunction(s)
        if isS4(s)
            tryEval(rlang_p(findNamespace("methods")[:show], :x), env, status)
        else
            tryEval(rlang_p(Const.BaseNamespace[:print], :x), env, status)
        end
    else
        # Rf_PrintValueRec not found on unix!?
        # ccall((:Rf_PrintValueRec,libR),Nothing,(Ptr{S},Ptr{EnvSxp}),s, Const.GlobalEnv)
        tryEval(rlang_p(Const.BaseNamespace[Symbol("print.default")], :x), env, status)
    end
    defineVar(:x, Const.NilValue, env)
    try
        handle_eval_stdout(io=io, force=true)
        handle_eval_stderr(as_warning=(status[] == 0))
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
rprint(r::Ptr{S}) where S<:Sxp = rprint(stdout, r)
rprint(r::RObject) = rprint(stdout, r)

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
    RParseError() = new("unknown parse error")
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
    read_console

`R_ReadConsole` API callback to read input.

See [Writing R extensions: Setting R callbacks](https://cran.r-project.org/doc/manuals/r-release/R-exts.html#Setting-R-callbacks)
"""
function read_console(p::Cstring, buf::Ptr{UInt8}, buflen::Cint, add_history::Cint)::Cint
    print(unsafe_string(p))
    linebuf = reenable_sigint() do
            Vector{UInt8}(readline())
        end

    m = min(length(linebuf), buflen - 2)
    for i in 1:m
        unsafe_store!(buf, linebuf[i], i)
    end
    unsafe_store!(buf, '\n', m + 1)
    unsafe_store!(buf, 0, m + 2)
    return Cint(1)
end

"""
    write_console_ex(buf::Ptr{UInt8},buflen::Cint,otype::Cint)::Cvoid

`R_WriteConsoleEx` API callback to write console output.

`otype` specifies the output type (regular output or warning/error).

See [Writing R extensions: Setting R callbacks](https://cran.r-project.org/doc/manuals/r-release/R-exts.html#Setting-R-callbacks)
"""
function write_console_ex(buf::Ptr{UInt8},buflen::Cint,otype::Cint)::Cvoid
    if otype == 0
        unsafe_write(output_buffer, buf, buflen)
    else
        unsafe_write(error_buffer, buf, buflen)
    end
    return nothing
end


function rconsole2str1_at(s::String)
    pos = findfirst("\x02\xff\xfe", s)
    if pos != nothing
        endpos = findfirst("\x03\xff\xfe", s[pos[end]+1:end])
        if endpos != nothing
            return (pos[end] + 1):(pos[end] + endpos[1] - 1)
        end
    end
end

function native_decode(s::String)
    s
end

function rconsole2str(s::String)
    ret = ""
    m = rconsole2str1_at(s)
    while m != nothing
        a = s[1:(first(m) - 1 - 3)]
        ret *= native_decode(a) * s[m]
        s = s[last(m) + 1 + 3: end]
        m = rconsole2str1_at(s)
    end
    ret *= native_decode(s)
end


function handle_eval_stdout(;io::IO=stdout, force::Bool=false)
    if (!_output_is_locked || force) && bytesavailable(output_buffer) != 0
        buf = String(take!(output_buffer))
        @static if Sys.iswindows()
            buf = rconsole2str(buf)
        end
        write(io, buf)
    end
end

function handle_eval_stderr(;as_warning::Bool=false)
    if bytesavailable(error_buffer) != 0
        s = String(take!(error_buffer))
        if as_warning
            @warn "RCall.jl: " * s
        else
            throw(REvalError(s))
        end
    end
end
