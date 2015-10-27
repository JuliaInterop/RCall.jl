@doc """
Evaluate an R symbol or language object (i.e. a function call) in an R
try/catch block, returning a Sxp pointer.
"""->
function reval_p{S<:Sxp}(expr::Ptr{S}, env::Ptr{EnvSxp})
    err = Array(Cint,1)
    val = ccall((:R_tryEval,libR),UnknownSxpPtr,(Ptr{S},Ptr{EnvSxp},Ptr{Cint}),expr,env,err)
    if err[1] !=0
        error("RCall.jl ", readall(RCall.errorBuffer))
    elseif nb_available(errorBuffer) != 0
        warn("RCall.jl ", readall(RCall.errorBuffer))
    end
    sexp(val)
end

function reval_p(expr::Ptr{ExprSxp}, env::Ptr{EnvSxp})
    local val           # the value of the last expression is returned
    protect(expr)
    for e in expr
        val = reval_p(e,env)
    end
    unprotect(1)
    val
end

reval_p{S<:Sxp}(s::Ptr{S}) = reval_p(s,rGlobalEnv)

@doc """
Evaluate an R symbol or language object (i.e. a function call) in an R
try/catch block, returning an RObject.
"""->
reval(s, env=rGlobalEnv) = RObject(reval_p(sexp(s),sexp(env)))
reval(str::AbstractString, env=rGlobalEnv) = reval(rparse_p(str))
reval(sym::Symbol, env=rGlobalEnv) = reval(sexp(sym))


@doc """
Evaluate and convert the result of a string as an R expression.
"""->
rcopy(str::AbstractString) = rcopy(reval_p(rparse_p(str)))
rcopy(sym::Symbol) = rcopy(reval_p(sexp(sym)))
rcopy{T}(::Type{T}, str::AbstractString) = rcopy(T, reval_p(rparse_p(str)))
rcopy{T}(::Type{T}, sym::Symbol) = rcopy(T, reval_p(sexp(sym)))


@doc "Parse a string as an R expression, returning a Sxp pointer."->
function rparse_p(st::Ptr{StrSxp})
    status = Array(Cint,1)
    val = ccall((:R_ParseVector,libR),UnknownSxpPtr,
                (Ptr{StrSxp},Cint,Ptr{Cint},UnknownSxpPtr),
                st,-1,status,rNilValue)
    s = status[1]
    if s != 1
        s == 2 && error("RCall.jl incomplete R expression")
        s == 3 && error("RCall.jl invalid R expression")
        s == 4 && throw(EOFError())
    end
    sexp(val)
end
rparse_p(st::AbstractString) = rparse_p(sexp(st))

@doc "Parse a string as an R expression, returning an RObject."->
rparse(st::AbstractString) = RObject(rparse_p(st))


@doc "Print the value of an Sxp using R's printing mechanism"->
function rprint{S<:Sxp}(io::IO, s::Ptr{S})
    protect(s)
    # Rf_PrintValue can cause segfault if S3 objects has custom
    # print function as it doesn't use R_tryEval
    # ccall((:Rf_PrintValue,libR),Void,(Ptr{S},),s)
    # below mirrors Rf_PrintValue
    env = protect(ccall((:Rf_NewEnvironment,libR),Ptr{EnvSxp},
            (Ptr{NilSxp},Ptr{NilSxp},Ptr{EnvSxp}),rNilValue,rNilValue,rGlobalEnv))
    xsym = protect(sexp(:x))
    ccall((:Rf_defineVar,libR),Void,(Ptr{SymSxp},Ptr{S},Ptr{EnvSxp}),xsym,s,env)
    if isObject(s) || isFunction(s)
        if isS4(s)
            methodsNamespace = protect(ccall((:R_FindNamespace,libR),Ptr{EnvSxp},
                (Ptr{StrSxp},), sexp("methods")))
            showFn = protect(ccall((:Rf_findVarInFrame3,libR),UnknownSxpPtr,
                (Ptr{EnvSxp}, Ptr{SymSxp}, Int32), methodsNamespace, sexp(:show), 1))
            reval(rlang_p(showFn, xsym),env)
            unprotect(2)
        else
            printFn = protect(ccall((:Rf_findVar,libR),UnknownSxpPtr,
                (Ptr{SymSxp},Ptr{EnvSxp}), sexp(:print), rBaseNamespace))
            reval(rlang_p(printFn, xsym),env)
            unprotect(1)
        end
    else
        # Rf_PrintValueRec not found on unix!?
        # ccall((:Rf_PrintValueRec,libR),Void,(Ptr{S},Ptr{EnvSxp}),s, rGlobalEnv)
        printFn = protect(ccall((:Rf_findVar,libR),UnknownSxpPtr,
            (Ptr{SymSxp},Ptr{EnvSxp}), sexp(symbol("print.default")), rBaseNamespace))
        reval(rlang_p(printFn, xsym),env)
        unprotect(1)
    end
    ccall((:Rf_defineVar,libR),Void,(Ptr{SymSxp},Ptr{S},Ptr{EnvSxp}),xsym,rNilValue,env)
    write(io,takebuf_string(printBuffer))
    unprotect(3)
    nothing
end
rprint(io::IO,r::RObject) = rprint(io,r.p)

rprint(s) = rprint(STDOUT,s)



@doc """
Parse, evaluate and print the result of a string as an R expression.
"""->
rprint(io::IO,str::ByteString) = rprint(io,reval(str))
rprint(io::IO,sym::Symbol) = rprint(io,reval(sym))

@doc """
Copies variables from Julia to R using the same name.
"""->
macro rput(args...)
    blk = Expr(:block)
    for a in args
        if isa(a,Symbol)
            v = a
            push!(blk.args,:(rGlobalEnv[$(QuoteNode(v))] = $(esc(v))))
        elseif isa(a,Expr) && a.head == :(::)
            v = a.args[1]
            S = a.args[2]
            push!(blk.args,:(rGlobalEnv[$(QuoteNode(v))] = sexp($S,$(esc(v)))))
        else
            error("Incorrect usage of @rput")
        end
    end
    blk
end

@doc """
Copies variables from R to Julia using the same name.
"""->
macro rget(args...)
    blk = Expr(:block)
    for a in args
        if isa(a,Symbol)
            v = a
            push!(blk.args,:($(esc(v)) = rcopy(rGlobalEnv[$(QuoteNode(v))])))
        elseif isa(a,Expr) && a.head == :(::)
            v = a.args[1]
            T = a.args[2]
            push!(blk.args,:($(esc(v)) = rcopy($(esc(T)),rGlobalEnv[$(QuoteNode(v))])))
        else
            error("Incorrect usage of @rget")
        end
    end
    blk
end
