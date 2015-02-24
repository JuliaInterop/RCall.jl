@doc "evaluate an R symbol or language object (i.e. a function call) in an R try/catch block"->
function reval(expr::SEXPREC, env::EnvSxp)
    err = Array(Cint,1)
    val = ccall((:R_tryEval,libR),Ptr{Void},(Ptr{Void},Ptr{Void},Ptr{Cint}),expr,env,err)
    bool(err[1]) && error("Error occurred in R_tryEval")
    sexp(val)
end
@doc "expression objects (the result of rparse) have a special reval method"->
function reval(expr::ExprSxp, env::EnvSxp) # evaluate result of R_ParseVector
    local val           # the value of the last expression is returned
    for e in expr
        val = reval(e,env)
    end
    val
end
reval(s::SEXPREC) = reval(s,globalEnv)
reval(sym::Symbol) = reval(sexp(sym))
reval(str::ByteString) = reval(rparse(str))

@doc "Parse a string as an R expression"->
function rparse(st::ASCIIString)
    ParseStatus = Array(Cint,1)
    val = ccall((:R_ParseVector,libR),Ptr{Void},
                (Ptr{Void},Cint,Ptr{Cint},Ptr{Void}),
                sexp(st),length(st),ParseStatus,nilValue)
    ParseStatus[1] == 1 || error("R_ParseVector set ParseStatus to $(ParseStatus[1])")
    sexp(val)
end

@doc "print the value of an SEXP using R's printing mechanism"->
rprint(s::SEXPREC) = ccall((:Rf_PrintValue,libR),Void,(Ptr{Void},),s)
rprint(str::ByteString) = rprint(reval(str))
rprint(sym::Symbol) = rprint(reval(sym))

rcopy(str::ByteString) = rcopy(reval(str))
rcopy(sym::Symbol) = rcopy(reval(sym))
