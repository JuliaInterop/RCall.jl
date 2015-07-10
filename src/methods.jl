function show(io::IO,r::RObject)
    println(io,typeof(r))
    rprint(io,r.p)
end

@doc """
The R NAMED property, represented by 2 bits in the info field. This can take
values 0,1 or 2, corresponding to whether it is bound to 0,1 or 2 or more
symbols. See
http://cran.r-project.org/doc/manuals/r-patched/R-exts.html#Named-objects-and-copying
"""->
function named{S<:SxpRec}(s::Ptr{S})
    u = unsafe_load(convert(UnknownSxp,s))
    (u.info >>> 6) & 0x03
end


@doc """
SxpRec methods for `length` return the R length.

`Rf_xlength` handles SxpRecs that are not vector-like and R's
"long vectors", which have a negative value for the `length` member.
"""->
length{S<:SxpRec}(s::Ptr{S}) =
    @compat Int(ccall((:Rf_xlength,libR),Cptrdiff_t,(Ptr{S},),s))
length(r::RObject) = length(r.p)

## Predicates applied to an SxpRec
##
## Many of these are unneeded but a few extra definitions is not a big deal
for sym in (:isArray,:isComplex,:isEnvironment,:isExpression,:isFactor,
            :isFrame,:isFree,:isFunction,:isInteger,:isLanguage,:isList,
            :isLogical,:isSymbol,:isMatrix,:isNewList,:isNull,:isNumeric,
            :isNumber,:isObject,:isOrdered,:isPairListSxpRec,:isPrimitiveSxpRec,
            :isReal,:isS4,:isString,:isTs,:isUnordered,:isUnsorted,
            :isUserBinop,:isValidString,:isValidStringF,:isVector,
            :isVectorAtomicSxpRec,:isVectorizable,:isVectorListSxpRec)
    @eval begin
        $sym{S<:SxpRec}(s::Ptr{S}) = ccall(($(string("Rf_",sym)),libR),Bool,(Ptr{SxpInfo},),s)
        $sym(r::RObject) = $sym(r.p)
    end
end

@doc """
Represent the contents of an VectorSxpRec type as a `Vector`.

This does __not__ copy the contents.  If the argument is not named (in R) or
otherwise protected from R's garbage collection (e.g. by keeping the
containing RObject in scope) the contents of this vector can be modified or
could cause a memory error when accessed.

The contents are as stored in R.  Missing values (NA's) are represented
in R by sentinels.  Missing data values in RealSxpRec and CplxSxpRec show
up as `NaN` and `NaN + NaNim`, respectively.  Missing data in IntSxpRec show up
as `-2147483648`, the minimum 32-bit integer value.  Internally a `LglSxpRec` is
represented as `Vector{Int32}`.  The convention is that `0` is `false`,
`-2147483648` is `NA` and all other values represent `true`.
"""->
unsafe_vec{S<:VectorSxpRec}(s::Ptr{S}) = pointer_to_array(convert(Ptr{eltype(S)}, s+voffset), length(s))
unsafe_vec{S<:VectorSxpRec}(r::RObject{S}) = unsafe_vec(r.p)


@doc """
Indexing into `VectorSxpRec` types uses Julia indexing into the `vec` result,
except for `StrSxpRec` and the `VectorListSxpRec` types, which must apply `sexp`
to the `Ptr{Void}` obtained by indexing into the `vec` result.
"""->
getindex{S<:VectorSxpRec}(s::Ptr{S}, I::Union(Real,AbstractVector)) = getindex(unsafe_vec(s),I)
getindex(s::Ptr{VecSxpRec}, I::Union(Real,AbstractVector)) = sexp(getindex(unsafe_vec(s),I))
getindex(s::Ptr{ExprSxpRec}, I::Union(Real,AbstractVector)) = sexp(getindex(unsafe_vec(s),I))

@doc """
String indexing finds the first element with the matching name
"""->
function getindex{S<:VectorSxpRec}(s::Ptr{S}, label::String)
    protect(s)
    ls = unsafe_vec(getNames(s))
    for (i,l) in enumerate(ls)
        if rcopy(l) == label
            return s[i]
        end
    end
    throw(BoundsError())
    unprotect(1)
end
getindex{S<:VectorSxpRec}(s::Ptr{S}, label::Symbol) = getindex(s,string(label))

function setindex!{S<:VectorAtomicSxpRec}(s::Ptr{S}, value, key)
    setindex!(unsafe_vec(s), value, key)
end
function setindex!(s::Ptr{StrSxpRec}, value::CharSxp, key::Integer)
    1 <= key <= length(s) || throw(BoundsError())
    ccall((:SET_STRING_ELT,libR), Void,
          (Ptr{StrSxpRec},Cptrdiff_t, CharSxp),
          s, key-1, value)
    return value
end
setindex!(s::Ptr{StrSxpRec}, value::String, key::Integer) =
    setindex!(s,sexp(CharSxpRec,value),key)

function setindex!{S<:Union(VecSxpRec,ExprSxpRec),T<:SxpRec}(s::Ptr{S}, value::Ptr{T}, key::Integer)
    1 <= key <= length(s) || throw(BoundsError())
    ccall((:SET_VECTOR_ELT,libR), Ptr{T},
          (Ptr{S},Cptrdiff_t, Ptr{T}),
          s, key-1, value)
end
setindex!{S<:Union(VecSxpRec,ExprSxpRec)}(s::Ptr{S}, value, key::Integer) =
    setindex!(s,sexp(value),key)


getindex{S<:VectorAtomicSxpRec}(r::RObject{S}, I) = getindex(r.p, I)
getindex{S<:VectorAtomicSxpRec}(r::RObject{S}, I::AbstractArray) = getindex(r.p, I)

getindex(r::RObject, I) = RObject(getindex(r.p,I))
getindex(r::RObject, I::AbstractArray) = map(RObject,getindex(r.p,I))

setindex!(r::RObject, value::RObject, key) = setindex!(r.p,value.p,key)




start{S<:VectorSxpRec}(s::Ptr{S}) = 0
next{S<:VectorSxpRec}(s::Ptr{S},state) = (state += 1;(s[state],state))
done{S<:VectorSxpRec}(s::Ptr{S},state) = state ≥ length(s)



# PairListSxpRecs

cdr{S<:PairListSxpRec}(s::Ptr{S}) = sexp(ccall((:CDR,libR),UnknownSxp,(Ptr{S},),s))
car{S<:PairListSxpRec}(s::Ptr{S}) = sexp(ccall((:CAR,libR),UnknownSxp,(Ptr{S},),s))
tag{S<:PairListSxpRec}(s::Ptr{S}) = sexp(ccall((:TAG,libR),UnknownSxp,(Ptr{S},),s))

setcar!{S<:PairListSxpRec,T<:SxpRec}(s::Ptr{S}, c::Ptr{T}) = (ccall((:SETCAR,libR),Ptr{Void},(Ptr{S},Ptr{T}),s,c); return nothing)
settag!{S<:PairListSxpRec,T<:SxpRec}(s::Ptr{S}, c::Ptr{T}) = ccall((:SET_TAG,libR),Void,(Ptr{S},Ptr{T}),s,c)


start{S<:PairListSxpRec}(s::Ptr{S}) = s
function next{S<:PairListSxpRec,T<:PairListSxpRec}(s::Ptr{S},state::Ptr{T})
    t = tag(state)
    c = car(state)
    (t,c), cdr(state)
end
done{S<:PairListSxpRec,T<:PairListSxpRec}(s::Ptr{S},state::Ptr{T}) = state == rNilValue

@doc "extract the i-th element of LangSxpRec l"->
function getindex{S<:PairListSxpRec}(l::Ptr{S},I::Integer)
    1 ≤ I ≤ length(l) || throw(BoundsError())
    for i in 2:I
        l = cdr(l)
    end
    car(l)
end

@doc "assign value v to the i-th element of LangSxpRec l"->
function setindex!{S<:PairListSxpRec,T<:SxpRec}(l::Ptr{S},v::Ptr{T},I::Integer)
    1 ≤ I ≤ length(l) || throw(BoundsError())
    for i in 2:I
        l = cdr(l)
    end
    setcar!(l,v)
end



function getAttrib{S<:SxpRec}(s::Ptr{S}, sym::Ptr{SymSxpRec})
    sexp(ccall((:Rf_getAttrib,libR),UnknownSxp,(Ptr{S},Ptr{SymSxpRec}),s,sym))
end
getAttrib{S<:SxpRec}(s::Ptr{S}, sym::Symbol) = getAttrib(s,sexp(SymSxpRec,sym))
getAttrib{S<:SxpRec}(s::Ptr{S}, sym::String) = getAttrib(s,sexp(SymSxpRec,sym))

getAttrib(r::RObject, sym) = RObject(getAttrib(r.p,sym))

function setAttrib!{S<:SxpRec,T<:SxpRec}(s::Ptr{S},sym::Ptr{SymSxpRec},t::Ptr{T})
    ccall((:Rf_setAttrib,libR),Ptr{Void},(Ptr{S},Ptr{SymSxpRec},Ptr{T}),s,sym,t)
    return nothing
end
setAttrib!{S<:SxpRec,T<:SxpRec}(s::Ptr{S},sym::Symbol,t::Ptr{T}) = setAttrib!(s,sexp(SymSxpRec,sym),t)
setAttrib!{S<:SxpRec,T<:SxpRec}(s::Ptr{S},sym::String,t::Ptr{T}) = setAttrib!(s,sexp(SymSxpRec,sym),t)
setAttrib!{S<:SxpRec}(s::Ptr{S},sym,t) = setAttrib!(s,sym,sexp(t))

setAttrib!(r::RObject, sym, t) = setAttrib!(r.p, sym, t)

attributes(s::SxpRecHead) = sexp(s.attrib)
attributes(s::SxpRec) = attributes(s.head)
attributes{S<:SxpRec}(s::Ptr{S}) = attributes(unsafe_load(s))


function size{S<:SxpRec}(s::Ptr{S})
    isArray(s) || return (length(s),)
    tuple(convert(Array{Int},unsafe_vec(getAttrib(s,rDimSymbol)))...)
end
size(r::RObject) = r


@doc """
Returns the names of an R vector.
"""->
getNames{S<:VectorSxpRec}(s::Ptr{S}) = getAttrib(s,rNamesSymbol)
getNames(r::RObject) = RObject(getNames(sexp(r)))




@doc """
Set the names of an R vector.
"""->
setNames!{S<:VectorSxpRec}(s::Ptr{S},n::Ptr{StrSxpRec}) = setAttrib!(s,rNamesSymbol,n)
setNames!(r::RObject,n) = RObject(setNames!(sexp(r)),sexp(StrSxpRec,n))

allocList(n::Int) = ccall((:Rf_allocList,libR),Ptr{ListSxpRec},(Cint,),n)
allocArray{S<:SxpRec}(::Type{S}, n::Integer) =
    ccall((:Rf_allocVector,libR),Ptr{S},(Cint,Cptrdiff_t),sexpnum(S),n)

allocArray{S<:SxpRec}(::Type{S}, n1::Integer, n2::Integer) =
    ccall((:Rf_allocMatrix,libR),Ptr{S},(Cint,Cint,Cint),sexpnum(S),n1,n2)

allocArray{S<:SxpRec}(::Type{S}, n1::Integer, n2::Integer, n3::Integer) =
    ccall((:Rf_alloc3DArray,libR),Ptr{S},(Cint,Cint,Cint,Cint),sexpnum(S),n1,n2,3)

function allocArray{S<:SxpRec}(::Type{S}, dims::Integer...)
    sdims = sexp(IntSxpRec,[dims...])
    ccall((:Rf_allocArray,libR),Ptr{S},(Cint,Ptr{IntSxpRec}),sexpnum(S),sdims)
end


@doc """
NA element for each type
"""->
NAel(::Type{LglSxpRec}) = rNaInt
NAel(::Type{IntSxpRec}) = rNaInt
NAel(::Type{RealSxpRec}) = rNaReal
NAel(::Type{CplxSxpRec}) = complex(rNaReal,rNaReal)
NAel(::Type{StrSxpRec}) = rNaString
NAel(::Type{VecSxpRec}) = sexp(LglSxpRec,rNaInt) # used for setting


@doc """
Check if values correspond to R's sentinel NA values.
"""->
isNA(x::Complex128) = real(x) === rNaReal && imag(x) === rNaReal
isNA(x::Float64) = x === rNaReal
isNA(x::Int32) = x == rNaInt
isNA(a::AbstractArray) = reshape(bitpack([isNA(aa) for aa in a]),size(a))
isNA(s::CharSxp) = s === rNaString

# this doesn't allow us to check VecSxpRec s
function isNA{S<:VectorSxpRec}(s::Ptr{S})
    b = BitArray(size(s)...)
    for (i,e) in enumerate(s)
        b[i] = isNA(e)
    end
    b
end

isNA(r::RObject) = isNA(r.p)


@doc """
Check if there are any NA values in the vector.
"""->
function anyNA{S<:VectorSxpRec}(s::Ptr{S})
    for i in s
        if isNA(s)
            return true
        end
    end
    return false
end



# EnvSxpRec

@doc "extract the value of symbol s in the environment e"->
function getindex(e::Ptr{EnvSxpRec},s::Ptr{SymSxpRec})
    v = ccall((:Rf_findVarInFrame,libR),UnknownSxp,(Ptr{EnvSxpRec},Ptr{SymSxpRec}),e,s)
    v == rUnboundValue && error("$s is not defined in the environment")
    sexp(v)
end


@doc "assign value v to symbol s in the environment e"->
function setindex!{S<:SxpRec}(e::Ptr{EnvSxpRec},v::Ptr{S},s::Ptr{SymSxpRec})
    # This should be done more carefully.  First check for the symbol in the
    # frame.  If it is defined call Rf_setVar, otherwise call Rf_defineVar.
    # As it stands this segfaults if the symbol is bound in, say, the base
    # environment.
    ccall((:Rf_setVar,libR),Void,(Ptr{SymSxpRec},Ptr{S},Ptr{EnvSxpRec}),s,v,e)
end
function setindex!(e::Ptr{EnvSxpRec},v,s::Symbol)
    sv = protect(sexp(v))
    ss = protect(sexp(s))
    setindex!(e,sv,ss)
    unprotect(2)
end
