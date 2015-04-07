## Methods related to the SEXP (pointer to SEXPREC type) in R

@doc "vector of R SEXPREC types"->
const typs = [NilSxp,SymSxp,ListSxp,ClosSxp,EnvSxp,PromSxp,LangSxp,SpecialSxp,BuiltinSxp,
              CharSxp,LglSxp,Void,Void,IntSxp,RealSxp,CplxSxp,StrSxp,DotSxp,AnySxp,
              VecSxp,ExprSxp,BcodeSxp,ExtPtrSxp,WeakRefSxp,RawSxp,S4Sxp]

@doc """
Convert a `Ptr{Void}` to the appropriate type that inherits from `SEXPREC`

The SEXPTYPE, determined from the trailing 5 bits of the first 32-bit word, is a 0-based
index into the `typs` vector.  A suitable SEXPREC type is instantiated.  The R SEXPREC
contains two pointers that are used by the generational garbage collector.  Those pointers
are not used in Julia and are overwritten by the original `Ptr{Void}` and,
for those types in the RVector union, a pointer to the contents of the vector.
"""->
function sexp(p::Ptr{Void})
    typ = (unsafe_load(convert(Ptr{Uint32},p)) & 0x1f)
    0 ≤ typ ≤ 10 || 13 ≤ typ ≤ 25 || error("Unknown SEXPTYPE $typ")
    jtyp = typs[typ+1]
    vv = unsafe_load(convert(Ptr{jtyp},p))
    vv.p = p
    jtyp <: RVector && (vv.pv = p + voffset)
    vv
end
sexp(v::Array{Ptr{Void}}) = map(sexp,v)

@doc "Create a `SymSxp` from a `Symbol`"->
sexp(s::Symbol) = sexp(ccall((:Rf_install,libR),Ptr{Void},(Ptr{Uint8},),string(s)))

@doc "Create a `StrSxp` from a `ByteString`"->
sexp(st::ByteString) = sexp(ccall((:Rf_mkString,libR),Ptr{Void},(Ptr{Uint8},),st))


##Create a `CharSxp` from a `ByteString`

##Note that a `CharSxp` is an internal R representation of a character string.
##An R assignment like `ff <- "foo"` creates a StrSxp which is a vector of
##character strings.

CharSxp(st::ByteString) = sexp(ccall((:Rf_mkChar,libR),Ptr{Void},(Ptr{Uint8},),st))

function sexp{T<:ByteString}(v::Array{T})
    rv = sexp(ccall((:Rf_allocVector,libR),Ptr{Void},(Cint,Cptrdiff_t),16,length(v)))
    vrv = vec(rv)
    for i in 1:length(v)
        vrv[i] = ccall((:Rf_mkChar,libR),Ptr{Void},(Ptr{Uint8},),v[i])
    end
    rv
end

## Predicates applied to an SEXPREC
##
## Many of these are unneeded but a few extra definitions is not a big deal
for sym in (:isArray,:isComplex,:isEnvironment,:isExpression,:isFactor,
            :isFrame,:isFree,:isFunction,:isInteger,:isLanguage,:isList,
            :isLogical,:isSymbol,:isMatrix,:isNewList,:isNull,:isNumeric,
            :isNumber,:isObject,:isOrdered,:isPairList,:isPrimitive,
            :isReal,:isS4,:isString,:isTs,:isUnordered,:isUnsorted,
            :isUserBinop,:isValidString,:isValidStringF,:isVector,
            :isVectorAtomic,:isVectorizable,:isVectorList)
    @eval $sym(s::SEXPREC) = ccall(($(string("Rf_",sym)),libR),Bool,(Ptr{Void},),s)
end

@doc """
Represent the contents of an RVector type as a `Vector`.

This does __not__ copy the contents.  If the argument is not
named (in R) or otherwise protected from R's garbage collection
the contents of this vector can be modified or could cause a
memory error when accessed.

The contents are as stored in R.  Missing values (NA's) are represented
in R by sentinels.  Missing data values in RealSxp and CplxSxp show
up as `NaN` and `NaN + NaNim`, respectively.  Missing data in IntSxp show up
as `-2147483648`, the minimum 32-bit integer value.  Internally a `LglSxp` is
represented as `Vector{Int32}`.  The convention is that `0` is `false`,
`-2147483648` is `NA` and all other values represent `true`.
"""->
Base.vec(s::RVector) = pointer_to_array(s.pv,s.length)
#Base.vec(s::VectorList) = map(sexp,pointer_to_array(s.pv,s.length))
#Base.vec(s::CharSxp) = bytestring(pointer_to_array(s.pv,s.length))

@doc """
Indexing into `RVector` types uses Julia indexing into the `vec` result,
except for `StrSxp` and the `VectorList` types, which must apply `sexp`
to the `Ptr{Void}` obtained by indexing into the `vec` result.
"""->
Base.getindex(s::VectorAtomic,I::Number) = getindex(vec(s),I)
Base.getindex(s::VectorList,I::Number) = sexp(getindex(vec(s),I))
Base.getindex(s::StrSxp,I::Number) = sexp(getindex(vec(s),I))

@doc """
`eltype` methods for RVector types are needed for v"0.3.x" and earlier.

In v"0.4" and later these can be expressed as `eltype(s.pv)`
"""->
Base.eltype(s::VectorAtomic) = eltype(vec(s))
Base.eltype(s::VectorList) = SEXPREC
Base.eltype(s::StrSxp) = CharSxp

Base.start(s::RVector) = 0
Base.next(s::RVector,state) = (state += 1;(s[state],state))
Base.done(s::RVector,state) = state ≥ length(s)

@doc "The R NAMED property, represented by 2 bits in the info field"->
named(s::SEXPREC) = (s.info >>> 6) & 0x03

function getAttrib(s::SEXPREC,sym::SymSxp)
    sexp(ccall((:Rf_getAttrib,libR),Ptr{Void},(Ptr{Void},Ptr{Void}),s,sym))
end
getAttrib(s::SEXPREC,sym::Symbol) = getAttrib(s,sexp(sym))
getAttrib(s::SEXPREC,str::ASCIIString) = getAttrib(s,symbol(str))

function Base.size(s::SEXPREC)
    isArray(s) || return (length(s),)
    tuple(convert(Array{Int},vec(getAttrib(s,dimSymbol)))...)
end

@doc """
`rcopy` copies the contents of an R object, preserving the dimensions
of the R object, if any.

A LglSxp is copied as `Int32` values, to be able to distinguish NA's from
other non-zeros.
""" ->
rcopy(p::Ptr{Void}) = rcopy(sexp(p))
rcopy(s::RVector) = reshape(copy(vec(s)),size(s))
rcopy(s::CharSxp) = bytestring(vec(s))
rcopy(s::SymSxp) = symbol(rcopy(sexp(s.pname)))
rcopy(s::StrSxp) = map(rcopy,vec(s))
rcopy(s::VecSxp) = map(rcopy,vec(s))
rcopy(s::NilSxp) = nothing

@doc """
Defines Julia `names` methods for `SEXPREC` types to return the R
names, if any.

This may not be the best idea because it makes these `names` methods
behave differently than all other `names` methods in `Julia`.
"""->
Base.names(s::SEXPREC) = ByteString[rcopy(nm) for nm in getAttrib(s,namesSymbol)]

isNA(s::Complex128) = x == R_NaReal + R_NaReal*im
isNA(x::Float64) = x == R_NaReal
isNA(x::Int32) = x == R_NaInt
isNA(x::ByteString) = x == bytestring(R_NaString)
isNA(a::Array) = reshape(bitpack([isNA(aa) for aa in a]),size(a))

DataArrays.DataArray(s::RVector) = (rc = rcopy(s);DataArray(rc,isNA(rc)))

## DataArray for an LglSxp converts from Cint to Bool
function DataArrays.DataArray(s::LglSxp)
    src = rcopy(s)
    DataArray(convert(Array{Bool},src), src .== R_NaInt)
end


## `DataArray` method for `IntSxp` returns a `PooledDataArray` for factors

## May not be the best idea because PooledDataArray is not a subtype of
## DataArray. Technically, returning a PooledDataArray from a DataArray
## method is a no-no.
function DataArrays.DataArray(s::IntSxp)
    if isFactor(s)
        ## refs array uses a zero index where R has a missing value, R_NaInt
        refs = DataArrays.RefArray(map!(x -> x == R_NaInt ? zero(Int32) : x,vec(s)))
        return compact(PooledDataArray(refs,rcopy(getAttrib(s,levelsSymbol))))
    end
    rc = rcopy(s)
    DataArray(rc,isNA(rc))
end

function DataFrames.DataFrame(s::VecSxp)
    isFrame(s) || error("s is not a R data frame")
    DataFrame(map(DataArray,s),map(symbol,names(s)))
end

## Evaluate a string and try to convert to a dataset
DataFrames.DataFrame(st::ASCIIString) = DataFrame(reval(st))

## Evaluate Symbol s as an R dataset
DataFrames.DataFrame(s::Symbol) = DataFrame(reval(s))

@doc "extract the value of symbol s in the environment e"->
Base.getindex(e::EnvSxp,s::Symbol) =
    sexp(ccall((:Rf_findVarInFrame,libR),Ptr{Void},(Ptr{Void},Ptr{Void}),e,sexp(s)))

@doc "assign value v to symbol s in the environment e"->
Base.setindex!(e::EnvSxp,v::SEXPREC,s::Symbol) =
    # This should be done more carefully.  First check for the symbol in the frame.  If it is
    # defined call Rf_setVar, otherwise call Rf_defineVar.  As it stands this segfaults if
    # the symbol is bound in, say, the base environment.
    ccall((:Rf_setVar,libR),Void,(Ptr{Void},Ptr{Void},Ptr{Void}),sexp(s),v,e)
Base.setindex!(e::EnvSxp,v,s::Symbol) = setindex!(e,sexp(v),s)

function preserve(s::SEXPREC)
    ccall((:R_PreserveObject,libR),Void,(Ptr{Void},),s)
    finalizer(s,x -> ccall((:R_ReleaseObject,libR),Void,(Ptr{Void},),x))
    s
end

for (typ,rtyp,rsnm) in ((:Bool, :Int32, "Logical"),
                        (:Complex, :Complex128, "Complex"),
                        (:Integer, :Int32, "Integer"),
                        (:Real, :Float64, "Real"))
    @eval sexp(v::$typ) = preserve(sexp(ccall(($(string("Rf_Scalar",rsnm)),libR),Ptr{Void},($rtyp,),v)))
end

for (typ,tag) in ((:Bool,10),(:Complex,15),(:Integer,13),(:Real,14))
    @eval begin
        function sexp{T<:$typ}(v::Vector{T})
            vv = preserve(sexp(ccall((:Rf_allocVector,libR),Ptr{Void},(Cint,Int),$tag,length(v))))
            copy!(vec(vv),v)
            vv
        end
        function sexp{T<:$typ}(m::Matrix{T})
            p,q = size(m)
            vv = preserve(sexp(ccall((:Rf_allocMatrix,libR),Ptr{Void},(Int,Cint,Cint),$tag,p,q)))
            copy!(vec(vv),m)
            vv
        end
        function sexp{T<:$typ}(a::Array{T,3})
            p,q,r = size(a)
            vv = preserve(sexp(ccall((:Rf_alloc3DArray,libR),Ptr{Void},
                                     (Cint,Cint,Cint,Cint),$tag,p,q,r)))
            copy!(vec(vv),a)
            vv
        end
    end
end

## To get rid of ambiguity, first define `sexp` for array with definite dimensions
## then arbitrary dimensions.
for (typ,tag) in ((:Bool,10),(:Complex,15),(:Integer,13),(:Real,14))
    @eval begin
        function sexp{T<:$typ}(a::Array{T})
            rdims = sexp([size(a)...])
            vv = preserve(sexp(ccall((:Rf_allocArray,libR),Ptr{Void},(Cint,Ptr{Void}),$tag,rdims)))
            copy!(vec(vv),a)
            vv
        end
    end
end

function sexp(v::BitVector)             # handled separately
    l = length(v)
    vv = preserve(sexp(ccall((:Rf_allocVector,libR),Ptr{Void},(Cint,Cptrdiff_t),10,l)))
    copy!(contents(vv),v)
    vv
end
