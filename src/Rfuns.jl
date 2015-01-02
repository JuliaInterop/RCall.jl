@doc "evaluate an R symbol or language object (i.e. a function call) in an R try/catch block"->
function tryEval(expr::SEXP, env::SEXP)
    isSymbol(expr) || isLanguage(expr) ||
        error("expr argument should be an R symbol or Language object")
    errorOccurred = Array(Cint,1)
    val = ccall((:R_tryEval,libR),SEXP,(SEXP,SEXP,Ptr{Cint}),expr,env,errorOccurred)
    Bool(errorOccurred[1]) && error("Error occurred in R_tryEval")
    val
end
tryEval(expr::SEXP) = tryEval(expr,globalEnv)
tryEval(sym::Symbol) = tryEval(install(string(sym)),globalEnv)

@doc "return the first element of an SEXP as an Complex128 value" ->
asComplex(s::SEXP) = ccall((:Rf_asComplex,libR),Complex128,(SEXP,),s)

@doc "return the first element of an SEXP as an Cint (i.e. Int32)" ->
asInteger(s::SEXP) = ccall((:Rf_asInteger,libR),Cint,(SEXP,),s)

@doc "return the first element of an SEXP as a Bool" ->
asLogical(s::SEXP) = ccall((:Rf_asLogical,libR),Bool,(SEXP,),s)

@doc "return the first element of an SEXP as a Cdouble (i.e. Float64)" ->
asReal(s::SEXP) = ccall((:Rf_asReal,libR),Cdouble,(SEXP,),s)

@doc "Symbol lookup for R, installing the symbol if necessary" ->
install(nm::ASCIIString) = ccall((:Rf_install,libR),SEXP,(Ptr{Uint8},),nm)
install(sym::Symbol) = install(string(sym))

@doc "find object with name sym in environment env"->
findVar(sym::SEXP,env::SEXP) = ccall((:Rf_findVar,libR),SEXP,(SEXP,SEXP),sym,env)
findVar(nm::ASCIIString,env::SEXP) = findVar(install(nm),env)
findVar(nm::ASCIIString) = findVar(install(nm),unsafe_load(cglobal((:R_globalEnv,libR),SEXP),1))

@doc "Check for S3 inheritance (I think only S3)"->
inherits(sexp::SEXP,cls::ASCIIString) = ccall((:Rf_inherits,libR),Bool,(SEXP,Ptr{Uint8}),sexp,cls)

## predicates applied to an SEXP
for sym in (:isArray,:isComplex,:isEnvironment,:isExpression,:isFactor,
            :isFrame,:isFree,:isFunction,:isInteger,:isLanguage,:isList,
            :isLogical,:isSymbol,:isMatrix,:isNewList,:isNull,:isNumeric,
            :isNumber,:isObject,:isOrdered,:isPairList,:isPrimitive,
            :isReal,:isS4,:isString,:isTs,:isUnordered,:isUnsorted,
            :isUserBinop,:isValidString,:isValidStringF,:isVector,
            :isVectorAtomic,:isVectorizable,:isVectorList)
    @eval $sym(s::SEXP) = ccall(($(string("Rf_",sym)),libR),Bool,(SEXP,),s)
end

@doc "Create a 0-argument function call from a symbol"->
lang1(sexp::SEXP) = ccall((:Rf_lang1,libR),SEXP,(SEXP,),sexp)

@doc "Create a 1-argument function call from a symbol and the argument"->
lang2(sxp1::SEXP,sxp2::SEXP) =
    ccall((:Rf_lang2,libR),SEXP,(SEXP,SEXP),sxp1,sxp2)

@doc "Create a 2-argument function call from a symbol and the arguments"->
lang3(sxp1::SEXP,sxp2::SEXP,sxp3::SEXP) =
    ccall((:Rf_lang3,libR),SEXP,(SEXP,SEXP,SEXP),sxp1,sxp2,sxp3)

Base.length(s::SEXP) = ccall((:Rf_length,libR),Cint,(SEXP,),s)

@doc "attach an R package"->
library(sym::Symbol) = tryEval(lang2(install(:library),install(sym)))

@doc "Create a string SEXP of length 1" ->
mkString(st::ASCIIString) = ccall((:Rf_mkString,libR),SEXP,(Ptr{Uint8},),st)

@doc "Protect an SEXP from garbage collection"->
protect(s::SEXP) = ccall((:Rf_protect,libR),SEXP,(SEXP,),s)

@doc "print the value of an SEXP"->
printValue(sexp::SEXP) = ccall((:Rf_PrintValue,libR),Void,(SEXP,),sexp)

@doc "Create an integer SEXP of length 1" ->
scalarInteger(i::Integer) = ccall((:Rf_ScalarInteger,libR),SEXP,(Cint,),i)

@doc "Create a logical SEXP of length 1" ->
scalarLogical(i::Integer) = ccall((:Rf_ScalarLogical,libR),SEXP,(Cint,),i)

@doc "Create a REAL SEXP of length 1"->
scalarReal(x::Real) = ccall((:Rf_ScalarReal,libR),SEXP,(Cdouble,),x)

@doc "Pop k elements off the protection stack"->
unprotect(k::Integer) = ccall((:Rf_unprotect,libR),Void,(Cint,),k)

@doc "unprotect an SEXP"->
unprotect(s::SEXP) = ccall((:Rf_unprotect_ptr,libR),Void,(SEXP,),s)

@doc "Get the names vector from an SEXP"->
function Base.names(sexp::SEXP)
    isVector(sexp) || return ASCIIString[]
    nms = ccall((:Rf_getAttrib,libR),SEXP,(SEXP,SEXP),sexp,install(:names))
    isString(nms) || return ASCIIString[]
    nnms = length(nms)
    val = Array(ASCIIString,nnms)
    for i in 1:nnms
        val[i] = copy(bytestring(ccall((:R_CHAR,libR),Ptr{Uint8},(SEXP,),
                                       ccall((:Rf_asChar,libR),SEXP,(SEXP,),
                                             ccall((:STRING_ELT,libR),SEXP,(SEXP,Cint),nms,i-1)))))
    end
    val
end
