mutable struct ProtectedEvalData
    f::Function
    args::Any
    ret::Ref{Any}
end


function protectedEval(pdata_t::Ptr{ProtectedEvalData})
    pdata = unsafe_pointer_to_objref(pdata_t)
    try
        pdata.ret[] = pdata.f(pdata.args...)
    catch e
        ccall((:Rf_error, libR), Cvoid, (Cstring,), string(e))
    end
    nothing
end

"""
A wrapper of R_ToplevelExec. It evaluates a given function with the given argument
within top level context, which will not result in a longjmp upon evaluation error.
"""
function rexec_p(f::Function, args...)
    ret = Ref{Any}()
    pdata = ProtectedEvalData(f, args, ret)
    protectedEval_t = @cfunction($protectedEval, Cvoid, (Ptr{ProtectedEvalData}, )).ptr
    status = ccall((:R_ToplevelExec, libR), Cint, (Ptr{Cvoid}, Ptr{Cvoid}), protectedEval_t, pointer_from_objref(pdata))
    if status == 0
        throw(ErrorException("rexec encountered an error"))
    end
    sexp(ret[])
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
    # use toplevelExec to evaluate parseVector as parseVector may longjmp
    result = protect(rexec_p(parseVector, st, status, sf))

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
