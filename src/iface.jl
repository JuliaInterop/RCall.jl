@doc """
Evaluate an R symbol or language object (i.e. a function call) in an R
try/catch block, returning a SxpRec pointer.
"""->
function reval_p{S<:SxpRec}(expr::Ptr{S}, env::Ptr{EnvSxpRec})
    err = Array(Cint,1)
    val = ccall((:R_tryEval,libR),UnknownSxp,(Ptr{S},Ptr{EnvSxpRec},Ptr{Cint}),expr,env,err)
    # TODO: figure out warnings: Rf_PrintWarnings not exported on all platforms.
    err[1]==0 || error("RCall.jl ",rcopy(rcall(:geterrmessage))[1])
    sexp(val)
end

function reval_p(expr::Ptr{ExprSxpRec}, env::Ptr{EnvSxpRec})
    local val           # the value of the last expression is returned
    for e in expr
        val = reval_p(e,env)
    end
    val
end

reval_p{S<:SxpRec}(s::Ptr{S}) = reval_p(s,rGlobalEnv)

@doc """
Evaluate an R symbol or language object (i.e. a function call) in an R
try/catch block, returning an RObject.
"""->
reval(s, env=rGlobalEnv) = RObject(reval_p(sexp(s),sexp(env)))
reval(str::String, env=rGlobalEnv) = reval(rparse_p(str))
reval(sym::Symbol, env=rGlobalEnv) = reval(sexp(sym))


@doc """
Evaluate and convert the result of a string as an R expression.
"""->
rcopy(str::String) = rcopy(reval_p(rparse_p(str)))
rcopy(sym::Symbol) = rcopy(reval_p(sexp(sym)))
rcopy{T}(::Type{T}, str::String) = rcopy(T, reval_p(rparse_p(str)))
rcopy{T}(::Type{T}, sym::Symbol) = rcopy(T, reval_p(sexp(sym)))


@doc "Parse a string as an R expression, returning a SxpRec pointer."->
function rparse_p(st::Ptr{StrSxpRec})
    ParseStatus = Array(Cint,1)
    val = ccall((:R_ParseVector,libR),UnknownSxp,
                (Ptr{StrSxpRec},Cint,Ptr{Cint},UnknownSxp),
                st,-1,ParseStatus,rNilValue)
    ParseStatus[1] == 1 || error("R_ParseVector set ParseStatus to $(ParseStatus[1])")
    sexp(val)
end
rparse_p(st::String) = rparse_p(sexp(st))

@doc "Parse a string as an R expression, returning an RObject."->
rparse(st::String) = RObject(rparse_p(st))


@doc "Print the value of an SxpRec using R's printing mechanism"->
function rprint{S<:SxpRec}(io::IO, s::Ptr{S})
    ccall((:Rf_PrintValue,libR),Void,(Ptr{S},),s)
    write(io,takebuf_string(printBuffer))
    nothing
end
rprint(io::IO,r::RObject) = rprint(io,r.p)

rprint(s) = rprint(STDOUT,s)



@doc """
Parse, evaluate and print the result of a string as an R expression.
"""->
rprint(io::IO,str::ByteString) = rprint(io,reval(str))
rprint(io::IO,sym::Symbol) = rprint(io,reval(sym))
