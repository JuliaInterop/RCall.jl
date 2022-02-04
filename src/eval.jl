# callback used by safe_parseVector
function safe_parseVector_callback(@nospecialize(args::Any))::Ptr{UnknownSxp}
    (st,status,sf) = args
    return ccall((:R_ParseVector,libR),Ptr{UnknownSxp},
        (Ptr{StrSxp},Cint,Ptr{Cint},Ptr{UnknownSxp}),
        st,-1,status,sf)
end
function safe_parseVector_handler(c::Ptr{UnknownSxp}, @nospecialize(_::Any))::Ptr{UnknownSxp}
    return c
end

"""
R_ParseVector wrapped by R_tryCatchError. It catches possible R's `stop` calls which may cause longjmp in C.

See [Writing R Extensions: Condition handling and cleanup code](https://cran.r-project.org/doc/manuals/r-release/R-exts.html#Condition-handling-and-cleanup-code)
"""
function safe_parseVector(st::Ptr{StrSxp}, status::Ref{Cint}, sf::Ptr{S}=sexp(Const.NilValue)) where S<:Sxp
    protect(st)
    protect(sf)
    ret = ccall((:R_tryCatchError, libR), Ptr{UnknownSxp},
          (Ptr{Cvoid}, Any, Ptr{Cvoid}, Any),
          @cfunction(safe_parseVector_callback, Ptr{UnknownSxp},(Any,)),
          (st,status,sf),
          @cfunction(safe_parseVector_handler, Ptr{UnknownSxp},(Ptr{UnknownSxp},Any)),
          nothing)
    unprotect(2)
    sexp(ret)
end


"A pure julia wrapper of R_ParseVector"
function parseVector(st::Ptr{StrSxp}, status::Ref{Cint}, sf::Ptr{S}=sexp(Const.NilValue)) where S<:Sxp
    protect(st)
    protect(sf)
    val = ccall((:R_ParseVector,libR),Ptr{UnknownSxp},
                (Ptr{StrSxp},Cint,Ptr{Cint},Ptr{UnknownSxp}),
                st,-1,status,sf)
    unprotect(2)
    sexp(val)
end

"Get the R parser error msg for the previous parsing result."
function getParseErrorMsg()
    unsafe_string(cglobal((:R_ParseErrorMsg, libR), UInt8))
end

"Parse a string as an R expression, returning a Sxp pointer."
function rparse_p(st::Ptr{StrSxp}, sf::Ptr{S}=sexp(Const.NilValue))  where S<:Sxp
    protect(st)
    protect(sf)
    status = Ref{Cint}()
    # use R_tryCatchError to evaluate parseVector as parseVector may longjmp
    result = protect(safe_parseVector(st, status, sf))

    try
        if "error" in rcopy(Array, getclass(result))
            throw(RParseError("Error: " * rcopy(result["message"])))
        else
            if status[] == 0
                throw(RParseError())
            elseif status[] == 2
                throw(RParseIncomplete("Error: " * getParseErrorMsg()))
            elseif status[] == 3
                throw(RParseError("Error: " * getParseErrorMsg()))
            elseif status[] == 4
                throw(RParseEOF())
            end
            sexp(result)
        end
    finally
        unprotect(3)
    end
end
rparse_p(st::AbstractString, sf::Ptr{S}=sexp(Const.NilValue)) where S<:Sxp = rparse_p(sexp(st), sf)
rparse_p(s::Symbol, sf::Ptr{S}=sexp(Const.NilValue)) where S<:Sxp = rparse_p(string(s), sf)

"Parse a string as an R expression, returning an RObject."
rparse(st::AbstractString) = RObject(rparse_p(st))


"""
A pure julia wrapper of R_tryEval.
"""
function tryEval(expr::Ptr{S}, env::Ptr{EnvSxp}=sexp(Const.GlobalEnv), status::Ref{Cint}=Ref{Cint}()) where S<:Sxp
    disable_sigint() do
        protect(expr)
        protect(env)
        val = ccall((:R_tryEval,libR),Ptr{UnknownSxp},(Ptr{S},Ptr{EnvSxp},Ref{Cint}),expr,env,status)
        unprotect(2)
        val
    end
end

"""
Evaluate an R symbol or language object (i.e. a function call) in an R
try/catch block, returning a Sxp pointer.
"""
function reval_p(expr::Ptr{S}, env::Ptr{EnvSxp}=sexp(Const.GlobalEnv)) where S<:Sxp
    status = Ref{Cint}()
    val = tryEval(expr, env, status)
    succeed = status[] == 0
    handle_eval_stdout()
    handle_eval_stderr(as_warning=succeed)
    # always throw an error if status is not zero
    !succeed && throw(REvalError())
    sexp(val)
end

"""
Evaluate an R expression array iteratively. If `throw_error` is `false`,
the error message and warning will be thrown to stderr.
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
