export dataset,
       findVar,
       isArray,
       isFactor,
       isMatrix,
       lang1,
       lang2,
       lang3,
       lang4,
       lang5,
       lang6,
       reval,
       rparse,
       rprint,
       sexp

@doc "evaluate an R symbol or language object (i.e. a function call) in an R try/catch block"->
function reval(expr::SEXP, env::SEXP{ENVSXP})
    err = Array(Cint,1)
    val = ccall((:R_tryEval,libR),Ptr{Void},(Ptr{Void},Ptr{Void},Ptr{Cint}),expr,env,err)
    bool(err[1]) && error("Error occurred in R_tryEval")
    sexp(val)
end

@doc "expression objects (the result of rparse) have a special reval method"->
function reval(expr::SEXP{EXPRSXP}, env::SEXP{ENVSXP}) # evaluate result of R_ParseVector
    local val           # the value of the last expression is returned
    for e in expr
        val = reval(e,env)
    end
    val
end
reval(s::SEXP) = reval(s,globalEnv)
reval(sym::Symbol) = reval(sexp(sym))

@doc "return the first element of an SEXP as an Complex128 value" ->
asComplex(s::SEXP) = ccall((:Rf_asComplex,libR),Complex128,(Ptr{Void},),s)

@doc "return the first element of an SEXP as an Cint (i.e. Int32)" ->
asInteger(s::SEXP) = ccall((:Rf_asInteger,libR),Cint,(Ptr{Void},),s)

@doc "return the first element of an SEXP as a Bool" ->
asLogical(s::SEXP) = ccall((:Rf_asLogical,libR),Bool,(Ptr{Void},),s)

@doc "return the first element of an SEXP as a Cdouble (i.e. Float64)" ->
asReal(s::SEXP) = ccall((:Rf_asReal,libR),Cdouble,(Ptr{Void},),s)

@doc "find object with name sym in environment env"->
findVar(sym::SEXP,env::SEXP{ENVSXP}=globalEnv) =
    sexp(ccall((:Rf_findVar,libR),Ptr{Void},(Ptr{Void},Ptr{Void}),sym,env))
findVar(nm::ASCIIString,env::SEXP{ENVSXP}) = findVar(sexp(symbol(nm)),env)
findVar(nm::ASCIIString) = findVar(sexp(symbol(nm)),globalEnv)

## predicates applied to an SEXP (many of these are unneeded for templated SEXP)
for sym in (:isArray,:isComplex,:isEnvironment,:isExpression,:isFactor,
            :isFrame,:isFree,:isFunction,:isInteger,:isLanguage,:isList,
            :isLogical,:isSymbol,:isMatrix,:isNewList,:isNull,:isNumeric,
            :isNumber,:isObject,:isOrdered,:isPairList,:isPrimitive,
            :isReal,:isS4,:isString,:isTs,:isUnordered,:isUnsorted,
            :isUserBinop,:isValidString,:isValidStringF,:isVector,
            :isVectorAtomic,:isVectorizable,:isVectorList)
    @eval $sym(s::SEXP) = ccall(($(string("Rf_",sym)),libR),Bool,(Ptr{Void},),s)
end

@doc "Create a 0-argument function call from a symbol"->
lang1(s::SEXP) = sexp(ccall((:Rf_lang1,libR),Ptr{Void},(Ptr{Void},),s))

@doc "Create a 1-argument function call from a symbol and the argument"->
lang2(s1::SEXP,s2::SEXP) =
    sexp(ccall((:Rf_lang2,libR),Ptr{Void},(Ptr{Void},Ptr{Void}),s1,s2))

@doc "Create a 2-argument function call from a symbol and the arguments"->
lang3(s1::SEXP,s2::SEXP,s3::SEXP) =
    sexp(ccall((:Rf_lang3,libR),Ptr{Void},
                 (Ptr{Void},Ptr{Void},Ptr{Void}),s1,s2,s3))

@doc "Create a 3-argument function call from a symbol and the arguments"->
lang4(s1::SEXP,s2::SEXP,s3::SEXP,s4::SEXP) =
    sexp(ccall((:Rf_lang3,libR),Ptr{Void},
                 (Ptr{Void},Ptr{Void},Ptr{Void},Ptr{Void}),s1,s2,s3,s4))

@doc "Create a 4-argument function call from a symbol and the arguments"->
lang5(s1::SEXP,s2::SEXP,s3::SEXP,s4::SEXP,s5::SEXP) =
    sexp(ccall((:Rf_lang3,libR),Ptr{Void},
                 (Ptr{Void},Ptr{Void},Ptr{Void},Ptr{Void},Ptr{Void}),s1,s2,s3,s4,s5))

@doc "Create a 5-argument function call from a symbol and the arguments"->
lang6(s1::SEXP,s2::SEXP,s3::SEXP,s4::SEXP,s5::SEXP,s6::SEXP) =
    sexp(ccall((:Rf_lang3,libR),Ptr{Void},
                 (Ptr{Void},Ptr{Void},Ptr{Void},Ptr{Void},Ptr{Void},Ptr{Void}),
                 s1,s2,s3,s4,s5,s6))

@doc "Protect an SEXP from garbage collection"->
protect(s::SEXP) = sexp(ccall((:Rf_protect,libR),Ptr{Void},(Ptr{Void},),s))

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
rprint(s::SEXP) = ccall((:Rf_PrintValue,libR),Void,(Ptr{Void},),s)

@doc "Pop k elements off the protection stack"->
unprotect(k::Integer) = ccall((:Rf_unprotect,libR),Void,(Cint,),k)

@doc "unprotect an SEXP"->
unprotect(s::SEXP) = ccall((:Rf_unprotect_ptr,libR),Void,(Ptr{Void},),s)

@doc "release an SEXP"->
ReleaseObject(s::SEXP) = ccall((:R_ReleaseObject,libR),Void,(Ptr{Void},),s)

@doc "preserve an SEXP"->
PreserveObject(s::SEXP) = ccall((:R_PreserveObject,libR),Void,(Ptr{Void},),s)
