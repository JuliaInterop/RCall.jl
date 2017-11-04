"""
A wrapper of R_ToplevelExec. It evaluates a given function with argument `data` at R top level. Useful to
catch possible Rf_error calls which may cause longjmp.
"""
function toplevelExec(fun::Function, data::Tuple)
    fptr = cfunction((dptr) -> fun(unsafe_pointer_to_objref(dptr)), Void, (Ptr{Void},))
    ccall((:R_ToplevelExec, libR), Cint, (Ptr{Void}, Ptr{Void}), fptr, pointer_from_objref(data))
end

function toplevelExec(fun::Function, input::Tuple, ret::Ref)
    toplevelExec((data) -> begin
        data[2][] = fun(data[1]...)
        nothing
    end, (input, ret))
end


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
    ret = Ref{Tuple{Ptr{UnknownSxp}, Cint}}()
    # use toplevelExec to evaluate parseVector as parseVector may longjmp
    if toplevelExec(parseVector, (st, sf), ret) == 0
        handle_eval_stderr(errortype=RParseError)
    else
        val, status = ret[]
        if status == 0
            throw(RParseError())
        elseif status == 2
            throw(RParseIncomplete("Error: " * getParseErrorMsg()))
        elseif status == 3
            throw(RParseError("Error: " * getParseErrorMsg()))
        elseif status == 4
            throw(RParseEOF())
        end
        sexp(val)
    end
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
    handle_eval_stdout()
    handle_eval_stderr(as_warning=(status == 0))
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
