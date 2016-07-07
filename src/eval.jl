"""
A pure julia wrapper of R_tryEval.
"""
function tryEval{S<:Sxp}(expr::Ptr{S}, env::Ptr{EnvSxp})
    disable_sigint() do
        status = Array(Cint,1)
        protect(expr)
        protect(env)
        val = ccall((:R_tryEval,libR),UnknownSxpPtr,(Ptr{S},Ptr{EnvSxp},Ptr{Cint}),expr,env,status)
        unprotect(2)
        val, status[1]
    end
end

"""
Evaluate an R symbol or language object (i.e. a function call) in an R
try/catch block, returning a Sxp pointer.
"""
function reval_p{S<:Sxp}(expr::Ptr{S}, env::Ptr{EnvSxp})
    val, status = tryEval(expr, env)
    flush_print_buffer(STDOUT)
    if status !=0
        error("RCall.jl: ", takebuf_string(errorBuffer))
    elseif nb_available(errorBuffer) != 0
        warn("RCall.jl: ", takebuf_string(errorBuffer))
    end
    sexp(val)
end

"""
Evaluate an R expression array iteratively.
"""
function reval_p(expr::Ptr{ExprSxp}, env::Ptr{EnvSxp})
    local val           # the value of the last expression is returned
    protect(expr)
    try
        for e in expr
            val = reval_p(e,env)
        end
    finally
        unprotect(1)
    end
    val
end

reval_p{S<:Sxp}(expr::Ptr{S}, env::RObject{EnvSxp}) = reval_p(expr,sexp(env))
reval_p{S<:Sxp}(s::Ptr{S}) = reval_p(s,Const.GlobalEnv)

"""
Evaluate an R symbol or language object (i.e. a function call) in an R
try/catch block, returning an RObject.
"""
function reval{S<:Sxp}(s::Ptr{S}, env=Const.GlobalEnv)
    ss = protect(s)
    local val
    try
        val = RObject(reval_p(ss,sexp(env)))
    finally
        unprotect(1)
    end
    val
end
reval(r::RObject, env=Const.GlobalEnv) = reval(sexp(r), env)
reval(str::AbstractString, env=Const.GlobalEnv) = reval(rparse_p(str),env)
reval(sym::Symbol, env=Const.GlobalEnv) = reval(sexp(sym),env)


"A pure julia wrapper of R_ParseVector"
function parseVector{S<:Sxp}(st::Ptr{StrSxp}, sf::Ptr{S}=sexp(Const.NilValue))
    protect(st)
    status = Array(Cint,1)
    val = ccall((:R_ParseVector,libR),UnknownSxpPtr,
                (Ptr{StrSxp},Cint,Ptr{Cint},UnknownSxpPtr),
                st,-1,status,sf)
    unprotect(1)
    val, status[1]
end

"Get the R parser error msg for the previous parsing result."
function getParseErrorMsg()
    Compat.unsafe_string(cglobal((:R_ParseErrorMsg, libR), UInt8))
end

"Parse a string as an R expression, returning a Sxp pointer."
function rparse_p(st::Ptr{StrSxp})
    val, status = parseVector(st)
    if status == 2 || status == 3
        error("RCall.jl: ", getParseErrorMsg())
    elseif status == 4
        throw(EOFError())
    end
    sexp(val)
end
rparse_p(st::AbstractString) = rparse_p(sexp(st))

"Parse a string as an R expression, returning an RObject."
rparse(st::AbstractString) = RObject(rparse_p(st))


"""
Evaluate and convert the result of a string as an R expression.
"""
rcopy(str::AbstractString) = rcopy(reval_p(rparse_p(str)))
rcopy(sym::Symbol) = rcopy(reval_p(sexp(sym)))
rcopy{T}(::Type{T}, str::AbstractString) = rcopy(T, reval_p(rparse_p(str)))
rcopy{T}(::Type{T}, sym::Symbol) = rcopy(T, reval_p(sexp(sym)))
