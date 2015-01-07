export asComplex,
       asInteger,
       asLogical,
       asReal,
       dataset,
       findVar,
       inherits,
       install,
       isArray,
       isFactor,
       isMatrix,
       lang1,
       lang2,
       lang3,
       lang4,
       lang5,
       lang6,
       mkString,
       Reval,
       Rparse,
       Rprint,
       scalarInteger,
       scalarLogical,
       scalarReal

@doc "evaluate an R symbol or language object (i.e. a function call) in an R try/catch block"->
function Reval(expr::SEXP, env::SEXP{4})
    errorOccurred = Array(Cint,1)
    val = asSEXP(ccall((:R_tryEval,libR),Ptr{Void},
                       (Ptr{Void},Ptr{Void},Ptr{Cint}),expr,env,errorOccurred))
    Bool(errorOccurred[1]) && error("Error occurred in R_Reval")
    val
end

@doc "expression objects (the result of Rparse) have a special Reval method"->
function Reval(expr::SEXP{20}, env::SEXP{4}) # evaluate result of R_ParseVector
    local val
    for I in 1:length(expr)
        val = Reval(asSEXP(ccall((:VECTOR_ELT,libR),Ptr{Void},(Ptr{Void},Int),expr,I-1)),env)
    end
    val
end
Reval(s::SEXP) = Reval(s,globalEnv)
Reval(sym::Symbol) = Reval(install(string(sym)),globalEnv)

@doc "return the first element of an SEXP as an Complex128 value" ->
asComplex(s::SEXP) = ccall((:Rf_asComplex,libR),Complex128,(Ptr{Void},),s)

@doc "return the first element of an SEXP as an Cint (i.e. Int32)" ->
asInteger(s::SEXP) = ccall((:Rf_asInteger,libR),Cint,(Ptr{Void},),s)

@doc "return the first element of an SEXP as a Bool" ->
asLogical(s::SEXP) = ccall((:Rf_asLogical,libR),Bool,(Ptr{Void},),s)

@doc "return the first element of an SEXP as a Cdouble (i.e. Float64)" ->
asReal(s::SEXP) = ccall((:Rf_asReal,libR),Cdouble,(Ptr{Void},),s)

@doc "convert a symbol or ASCIIString to a dataset"->
function dataset(sym::Symbol)
    vv = Reval(sym)
    R.inherits(vv,"data.frame") || error("Needs a data frame")
    DataFrame([DataArray(vv[i]) for i in 1:length(vv)],convert(Vector{Symbol},names(vv)))
end

@doc "Symbol lookup for R, installing the symbol if necessary" ->
install(nm::ASCIIString) = asSEXP(ccall((:Rf_install,libR),Ptr{Void},(Ptr{Uint8},),nm))
install(sym::Symbol) = install(string(sym))

@doc "find object with name sym in environment env"->
findVar(sym::SEXP,env::SEXP{4}=globalEnv) =
    asSEXP(ccall((:Rf_findVar,libR),Ptr{Void},(Ptr{Void},Ptr{Void}),sym.p,env.p))
findVar(nm::ASCIIString,env::SEXP{4}) = findVar(install(nm),env)
findVar(nm::ASCIIString) = findVar(install(nm),globalEnv)

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
lang1(s::SEXP) = asSEXP(ccall((:Rf_lang1,libR),Ptr{Void},(Ptr{Void},),s))

@doc "Create a 1-argument function call from a symbol and the argument"->
lang2(s1::SEXP,s2::SEXP) =
    asSEXP(ccall((:Rf_lang2,libR),Ptr{Void},(Ptr{Void},Ptr{Void}),s1,s2))

@doc "Create a 2-argument function call from a symbol and the arguments"->
lang3(s1::SEXP,s2::SEXP,s3::SEXP) =
    asSEXP(ccall((:Rf_lang3,libR),Ptr{Void},
                 (Ptr{Void},Ptr{Void},Ptr{Void}),s1,s2,s3))

@doc "Create a 3-argument function call from a symbol and the arguments"->
lang4(s1::SEXP,s2::SEXP,s3::SEXP,s4::SEXP) =
    asSEXP(ccall((:Rf_lang3,libR),Ptr{Void},
                 (Ptr{Void},Ptr{Void},Ptr{Void},Ptr{Void}),s1,s2,s3,s4))

@doc "Create a 4-argument function call from a symbol and the arguments"->
lang5(s1::SEXP,s2::SEXP,s3::SEXP,s4::SEXP,s5::SEXP) =
    asSEXP(ccall((:Rf_lang3,libR),Ptr{Void},
                 (Ptr{Void},Ptr{Void},Ptr{Void},Ptr{Void},Ptr{Void}),s1,s2,s3,s4,s5))

@doc "Create a 5-argument function call from a symbol and the arguments"->
lang6(s1::SEXP,s2::SEXP,s3::SEXP,s4::SEXP,s5::SEXP,s6::SEXP) =
    asSEXP(ccall((:Rf_lang3,libR),Ptr{Void},
                 (Ptr{Void},Ptr{Void},Ptr{Void},Ptr{Void},Ptr{Void},Ptr{Void}),
                 s1,s2,s3,s4,s5,s6))

@doc "Create a string SEXP of length 1" ->
mkString(st::ASCIIString) = asSEXP(ccall((:Rf_mkString,libR),Ptr{Void},(Ptr{Uint8},),st))

@doc "Protect an SEXP from garbage collection"->
protect(s::SEXP) = asSEXP(ccall((:Rf_protect,libR),Ptr{Void},(Ptr{Void},),s))

@doc "Parse a string as an R expression"->
function Rparse(st::ASCIIString)
    ParseStatus = Array(Cint,1)
    val = ccall((:R_ParseVector,libR),Ptr{Void},
                (Ptr{Void},Cint,Ptr{Cint},Ptr{Void}),
                mkString(st),length(st),ParseStatus,nilValue)
    ParseStatus[1] == 1 || error("R_ParseVector set ParseStatus to $(ParseStatus[1])")
    asSEXP(val)
end

@doc "print the value of an SEXP using R's printing mechanism"->
Rprint(s::SEXP) = ccall((:Rf_PrintValue,libR),Void,(Ptr{Void},),s)

@doc "Create an integer SEXP of length 1" ->
scalarInteger(i::Integer) = SEXP{13}(ccall((:Rf_ScalarInteger,libR),Ptr{Void},(Cint,),i))

@doc "Create a logical SEXP of length 1" ->
scalarLogical(i::Integer) = SEXP{10}(ccall((:Rf_ScalarLogical,libR),Ptr{Void},(Cint,),i))

@doc "Create a REAL SEXP of length 1"->
scalarReal(x::Real) = SEXP{14}(ccall((:Rf_ScalarReal,libR),Ptr{Void},(Cdouble,),x))

@doc "Pop k elements off the protection stack"->
unprotect(k::Integer) = ccall((:Rf_unprotect,libR),Void,(Cint,),k)

@doc "unprotect an SEXP"->
unprotect(s::SEXP) = ccall((:Rf_unprotect_ptr,libR),Void,(Ptr{Void},),s.p)

@doc "release an SEXP"->
ReleaseObject(s::SEXP) = ccall((:R_ReleaseObject,libR),Void,(Ptr{Void},),s.p)

@doc "preserve an SEXP"->
PreserveObject(s::SEXP) = ccall((:R_PreserveObject,libR),Void,(Ptr{Void},),s.p)
