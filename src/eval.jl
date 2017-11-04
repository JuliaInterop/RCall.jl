"A pure julia wrapper of R_ParseVector"
function parseVector(st::Ptr{StrSxp}, sf::Ptr{S}=sexp(Const.NilValue)) where S<:Sxp
    protect(st)
    protect(sf)
    status = Ref{Cint}()
    val = ccall((:R_ParseVector,libR),Ptr{UnknownSxp},
                (Ptr{StrSxp},Cint,Ptr{Cint},Ptr{UnknownSxp}),
                st,-1,status,sf)
    unprotect(2)
    val, status[]
end

"Get the R parser error msg for the previous parsing result."
function getParseErrorMsg()
    unsafe_string(cglobal((:R_ParseErrorMsg, libR), UInt8))
end

"Parse a string as an R expression, returning a Sxp pointer."
function rparse_p(st::Ptr{StrSxp}, sf::Ptr{S}=sexp(Const.NilValue))  where S<:Sxp
    val, status = parseVector(st, sf)
    if status == 0
        throw(RParseError())
    elseif status == 2
        throw(RParseIncomplete(getParseErrorMsg()))
    elseif status == 3
        throw(RParseError(getParseErrorMsg()))
    elseif status == 4
        throw(RParseEOF())
    end
    sexp(val)
end
rparse_p(st::AbstractString, sf::Ptr{S}=sexp(Const.NilValue)) where S<:Sxp = rparse_p(sexp(st), sf)
rparse_p(s::Symbol, sf::Ptr{S}=sexp(Const.NilValue)) where S<:Sxp = rparse_p(string(s), sf)

"Parse a string as an R expression, returning an RObject."
rparse(st::AbstractString) = RObject(rparse_p(st))


"""
A pure julia wrapper of R_tryEval.
"""
function tryEval(expr::Ptr{S}, env::Ptr{EnvSxp}=sexp(Const.GlobalEnv)) where S<:Sxp
    disable_sigint() do
        status = Ref{Cint}()
        protect(expr)
        protect(env)
        val = ccall((:R_tryEval,libR),Ptr{UnknownSxp},(Ptr{S},Ptr{EnvSxp},Ref{Cint}),expr,env,status)
        unprotect(2)
        val, status[]
    end
end

"""
Evaluate an R symbol or language object (i.e. a function call) in an R
try/catch block, returning a Sxp pointer.
"""
function reval_p(expr::Ptr{S}, env::Ptr{EnvSxp}=sexp(Const.GlobalEnv)) where S<:Sxp
    val, status = tryEval(expr, env)
    handle_eval_stdout(status)
    handle_eval_stderr(status)
    sexp(val)
end

"""
Evaluate an R expression array iteratively. If `throw_error` is `false`,
the error message and warning will be thrown to STDERR.
"""
function reval_p(expr::Ptr{ExprSxp}, env::Ptr{EnvSxp})
    local val
    protect(expr)
    protect(env)
    try
        for e in expr
            val = reval_p(e, env)
        end
    finally
        unprotect(2)
    end
    # set .Last.value
    if env == Const.GlobalEnv.p
        set_last_value(val)
    end
    val
end

"""
Evaluate an R symbol or language object (i.e. a function call) in an R
try/catch block, returning an RObject.
"""
reval(r::RObject, env=Const.GlobalEnv) = RObject(reval_p(sexp(r), sexp(env)))
reval(str::T, env=Const.GlobalEnv) where T <: Union{AbstractString, Symbol} =
    RObject(reval_p(rparse_p(str), sexp(env)))
