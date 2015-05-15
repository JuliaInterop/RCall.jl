## Methods related to the SEXP (pointer to SEXPREC type) in R

@doc "vector of R SEXPREC types"->
const typs = [NilSxp,SymSxp,ListSxp,ClosSxp,EnvSxp,PromSxp,LangSxp,SpecialSxp,BuiltinSxp,
              CharSxp,LglSxp,Void,Void,IntSxp,RealSxp,CplxSxp,StrSxp,DotSxp,AnySxp,
              VecSxp,ExprSxp,BcodeSxp,ExtPtrSxp,WeakRefSxp,RawSxp,S4Sxp]

sexp(s::SEXPREC) = s

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

@doc """
Create a `CharSxp` from a String.

Note that a `CharSxp` is an internal R representation of a character string.
An R assignment like `ff <- \"foo\"` creates a StrSxp which is a vector of
character strings.
"""->
CharSxp(st::ASCIIString) = sexp(ccall((:Rf_mkCharLen,libR),Ptr{Void},(Ptr{Uint8},Cint),st,sizeof(st)))
CharSxp(st::UTF8String) = sexp(ccall((:Rf_mkCharLenCE,libR),Ptr{Void},(Ptr{Uint8},Cint,Cint),st,sizeof(st),1))
CharSxp(st::String) = CharSxp(bytestring(st))

@doc """
Determines the encoding of the CharSxp. This is determined by the 'gp' part of the sxpinfo (this is the middle 16 bits).
 * 0x00_0002_00 (bit 1): set of bytes (no known encoding)
 * 0x00_0004_00 (bit 2): Latin-1
 * 0x00_0008_00 (bit 3): UTF-8
 * 0x00_4000_00 (bit 6): ASCII
"""->
function encoding(s::CharSxp)
    if s.info & 0x00_0040_00 != 0
        return ASCIIString
    elseif s.info & 0x00_0008_00 != 0
        return UTF8String
    else
        error("Unknown string type")
    end
end

StrSxp(s::CharSxp) = sexp(ccall((:Rf_ScalarString,libR),Ptr{Void},(Ptr{Void},),s.p))

@doc "Create a `StrSxp` from a `ByteString`"->
sexp(st::String) = StrSxp(CharSxp(bytestring(st)))


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

function setAttrib(s::SEXPREC,sym::SymSxp,t::SEXPREC)
    sexp(ccall((:Rf_setAttrib,libR),Ptr{Void},(Ptr{Void},Ptr{Void},Ptr{Void}),s,sym,t))
end
setAttrib(s::SEXPREC,sym::Symbol,t::SEXPREC) = setAttrib(s,sexp(sym),t)
setAttrib(s::SEXPREC,str::ASCIIString,t::SEXPREC) = setAttrib(s,symbol(str),t)

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
Base.names(s::SEXPREC) = rcopy(getAttrib(s,namesSymbol))

isNA(x::Complex128) = real(x) === R_NaReal && imag(x) === R_NaReal
isNA(x::Float64) = x === R_NaReal
isNA(x::Int32) = x == R_NaInt
isNA(a::AbstractArray) = reshape(bitpack([isNA(aa) for aa in a]),size(a))
isNA(s::CharSxp) = s.p == R_NaString.p

DataArrays.DataArray(s::RVector) = (rc = rcopy(s);DataArray(rc,isNA(rc)))

## handle StrSxp seperately
function DataArrays.DataArray(s::StrSxp)
    na = Bool[x.p == R_NaString.p for x in s]
    DataArray(rcopy(s), na)
end

## DataArray for an LglSxp converts from Cint to Bool
function DataArrays.DataArray(s::LglSxp)
    src = rcopy(s)
    na = src .== R_NaInt
    ## R_NaInt is -2147483648 and
    ## in v.0.4, convert(Array{Bool}, [-2147483648]) throws InexactError(),
    ## those values need to be set to zero or one.
    src[na] = 0
    DataArray(convert(Array{Bool},src), na)
end

## `DataArray` method for `IntSxp` throws error message for factors
function DataArrays.DataArray(s::IntSxp)
    isFactor(s) && error("s is a R factor, use `PooledDataArray` instead")
    rc = rcopy(s)
    DataArray(rc,isNA(rc))
end

## `PooledDataArray` method for `IntSxp` returns a `PooledDataArray` for factors
function DataArrays.PooledDataArray(s::IntSxp)
    isFactor(s) || error("s is not a R factor")
    ## refs array uses a zero index where R has a missing value, R_NaInt
    refs = DataArrays.RefArray(map!(x -> x == R_NaInt ? zero(Int32) : x,vec(s)))
    return compact(PooledDataArray(refs,rcopy(getAttrib(s,levelsSymbol))))
end

function DataFrames.DataFrame(s::VecSxp)
    isFrame(s) || error("s is not a R data frame")
    DataFrame(map((x)->isFactor(x)? PooledDataArray(x) : DataArray(x) ,s), map(symbol,names(s)))
end

## Evaluate a string and try to convert to a dataset
DataFrames.DataFrame(st::ASCIIString) = DataFrame(reval(st))

## Evaluate Symbol s as an R dataset
DataFrames.DataFrame(s::Symbol) = DataFrame(reval(s))

@doc "extract the value of symbol s in the environment e"->
function Base.getindex(e::EnvSxp,s::Symbol)
    v = ccall((:Rf_findVarInFrame,libR),Ptr{Void},(Ptr{Void},Ptr{Void}),e,sexp(s))
    v == unboundValue.p && error("$s is not defined in the environment")
    sexp(v)
end

@doc "assign value v to symbol s in the environment e"->
Base.setindex!(e::EnvSxp,v::SEXPREC,s::Symbol) =
    # This should be done more carefully.  First check for the symbol in the frame.  If it is
    # defined call Rf_setVar, otherwise call Rf_defineVar.  As it stands this segfaults if
    # the symbol is bound in, say, the base environment.
    ccall((:Rf_setVar,libR),Void,(Ptr{Void},Ptr{Void},Ptr{Void}),sexp(s),v,e)
Base.setindex!(e::EnvSxp,v,s::Symbol) = setindex!(e,sexp(v),s)

@doc "extract the i-th element of LangSxp l"->
function Base.getindex(l::LangSxp,I::Integer)
    1 ≤ I ≤ length(l) || throw(BoundsError())
    if I ≥ 2
        for i in 2:I
            l = ccall((:CDR,libR),Ptr{Void},(Ptr{Void},),l)
        end
    end
    sexp(ccall((:CAR,libR),Ptr{Void},(Ptr{Void},),l))
end

@doc "assign value v to the i-th element of LangSxp l"->
function Base.setindex!(l::LangSxp,v::SEXPREC,I::Integer)
    1 ≤ I ≤ length(l) || throw(BoundsError())
    if I ≥ 2
        for i in 2:I
            l = ccall((:CDR,libR),Ptr{Void},(Ptr{Void},),l)
        end
    end
    sexp(ccall((:SETCAR,libR),Ptr{Void},(Ptr{Void},Ptr{Void}),l,v))
end

function preserve(s::SEXPREC)
    ccall((:R_PreserveObject,libR),Void,(Ptr{Void},),s)
    finalizer(s,x -> ccall((:R_ReleaseObject,libR),Void,(Ptr{Void},),x))
    s
end

## AbstractArray to sexp conversion.

function sexp{T<:ByteString}(v::AbstractArray{T})
    rv = preserve(sexp(ccall((:Rf_allocVector,libR),Ptr{Void},(Cint,Cptrdiff_t),16,length(v))))
    vrv = vec(rv)
    for i in 1:length(v)
        vrv[i] = ccall((:Rf_mkChar,libR),Ptr{Void},(Ptr{Uint8},),v[i])
    end
    rv
end

for (typ,rtyp,rsnm) in ((:Bool, :Int32, "Logical"),
                        (:Integer, :Int32, "Integer"),
                        (:Real, :Float64, "Real"),
                        (:Complex, :Complex128, "Complex"))
    @eval sexp(v::$typ) = preserve(sexp(ccall(($(string("Rf_Scalar",rsnm)),libR),Ptr{Void},($rtyp,),v)))
end

for (typ,tag) in ((:Bool,10),(:Integer,13),(:Real,14),(:Complex,15))
    @eval begin
        function sexp{T<:$typ}(v::AbstractVector{T})
            vv = preserve(sexp(ccall((:Rf_allocVector,libR),Ptr{Void},(Cint,Int),$tag,length(v))))
            copy!(vec(vv),v)
            vv
        end
        function sexp{T<:$typ}(m::AbstractMatrix{T})
            p,q = size(m)
            vv = preserve(sexp(ccall((:Rf_allocMatrix,libR),Ptr{Void},(Int,Cint,Cint),$tag,p,q)))
            copy!(vec(vv),m)
            vv
        end
        function sexp{T<:$typ}(a::AbstractArray{T,3})
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
for (typ,tag) in ((:Bool,10),(:Integer,13),(:Real,14),(:Complex,15))
    @eval begin
        function sexp{T<:$typ}(a::AbstractArray{T})
            rdims = sexp([size(a)...])
            vv = preserve(sexp(ccall((:Rf_allocArray,libR),Ptr{Void},(Cint,Ptr{Void}),$tag,rdims)))
            copy!(vec(vv),a)
            vv
        end
    end
end

## DataArray to sexp conversion.
function sexp{T<:ByteString}(v::DataArray{T})
    rv = sexp(v.data)
    for i in find(v.na)
        ccall((:SET_STRING_ELT,libR),Ptr{Void},(Ptr{Void},Cint,Ptr{Void}),rv,i-1,R_NaString)
    end
    rv
end

for (typ,na_sym) in ((:Bool,:R_NaInt),(:Integer,:R_NaInt),(:Real,:R_NaReal))
    @eval begin
        function sexp{T<:$typ}(a::DataArray{T})
            vv = sexp(a.data)
            vec(vv)[a.na] = $na_sym
            vv
        end
    end
end

## handle complex numnbers separately
function sexp{T<:Complex}(a::DataArray{T})
    vv = sexp(a.data)
    p = convert(Ptr{Float64}, vv.pv)
    for i in find(a.na)
        unsafe_store!(p,R_NaReal,2i-1) # real part
        unsafe_store!(p,R_NaReal,2i) # imaginary part
    end
    vv
end

## PooledDataArray to sexp conversion.
function sexp{T<:ByteString,R<:Integer}(v::PooledDataArray{T,R})
    rv = sexp(v.refs)
    setAttrib(rv, levelsSymbol, sexp(v.pool))
    setAttrib(rv, classSymbol, sexp("factor"))
    rv
end

## DataFrame to sexp conversion.
function sexp(d::DataFrames.DataFrame)
    nr,nc = size(d)
    rd = preserve(sexp(ccall((:Rf_allocVector,libR),Ptr{Void},(Cint,Cptrdiff_t),19,nc)))
    for i in 1:nc
        col_values = d[d.colindex.names[i]]
        ccall((:SET_VECTOR_ELT,libR),Ptr{Void},(Ptr{Void},Cint,Ptr{Void}),rd,i-1,sexp(col_values))
    end
    setAttrib(rd,namesSymbol,sexp(ByteString[string(n) for n in d.colindex.names]))
    setAttrib(rd,classSymbol, sexp("data.frame"))
    setAttrib(rd,rowNamesSymbol, sexp(1:nr))
    rd
end

function sexp(v::BitVector)             # handled separately
    l = length(v)
    vv = preserve(sexp(ccall((:Rf_allocVector,libR),Ptr{Void},(Cint,Cptrdiff_t),10,l)))
    copy!(contents(vv),v)
    vv
end
