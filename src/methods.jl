"""
The R NAMED property, represented by 2 bits in the info field. This can take
values 0,1 or 2, corresponding to whether it is bound to 0,1 or 2 or more
symbols. See
http://cran.r-project.org/doc/manuals/r-patched/R-exts.html#Named-objects-and-copying
"""
function bound(s::Ptr{S}) where S<:Sxp
    u = unsafe_load(convert(Ptr{UnknownSxp},s))
    (u.info >>> 6) & 0x03
end


"""
Sxp methods for `length` return the R length.

`Rf_xlength` handles Sxps that are not vector-like and R's
"long vectors", which have a negative value for the `length` member.
"""
length(s::Ptr{S}) where S<:Sxp = Int(ccall((:Rf_xlength,libR),Cptrdiff_t,(Ptr{S},),s))
length(r::RObject) = length(r.p)

## Predicates applied to an Sxp
##
## Many of these are unneeded but a few extra definitions is not a big deal
for sym in (:isArray,:isComplex,:isEnvironment,:isExpression,:isFactor,
            :isFrame,:isFree,:isFunction,:isInteger,:isLanguage,:isList,
            :isLogical,:isSymbol,:isMatrix,:isNewList,:isNull,:isNumeric,
            :isNumber,:isObject,:isOrdered,:isPairList,:isPrimitive,
            :isReal,:isS4,:isString,:isTs,:isUnordered,:isUnsorted,
            :isUserBinop,:isValidString,:isValidStringF,:isVector,
            :isVectorAtomic,:isVectorizable,:isVectorList)
    @eval begin
        $sym(s::Ptr{S}) where S<:Sxp = ccall(($(string("Rf_",sym)),libR),Bool,(Ptr{SxpPtrInfo},),s)
        $sym(r::RObject) = $sym(r.p)
    end
end

for (S, J) in ((:LglSxp, "LOGICAL"), (:IntSxp, "INTEGER"),
                (:RealSxp, "REAL"), (:CplxSxp, "COMPLEX"), (:RawSxp, "RAW"))
    @eval dataptr(s::Ptr{$S}) = convert(Ptr{eltype($S)}, ccall(($J,libR), Ptr{Cvoid}, (Ptr{UnknownSxp},), s))
end

"""
Represent the contents of a VectorSxp type as a `Vector`.

This does __not__ copy the contents.  If the argument is not named (in R) or
otherwise protected from R's garbage collection (e.g. by keeping the
containing RObject in scope) the contents of this vector can be modified or
could cause a memory error when accessed.

The contents are as stored in R.  Missing values (NA's) are represented
in R by sentinels.  Missing data values in RealSxp and CplxSxp show
up as `NaN` and `NaN + NaNim`, respectively.  Missing data in IntSxp show up
as `-2147483648`, the minimum 32-bit integer value.  Internally a `LglSxp` is
represented as `Vector{Int32}`.  The convention is that `0` is `false`,
`-2147483648` is `NA` and all other values represent `true`.
"""
unsafe_vec(s::Ptr{S}) where S<:VectorSxp = unsafe_wrap(Array, dataptr(s), length(s))
unsafe_vec(r::RObject{S}) where S<:VectorSxp = unsafe_vec(r.p)

"""
The same as `unsafe_vec`, except returns an appropriately sized array.
"""
unsafe_array(s::Ptr{S}) where S<:VectorSxp =  unsafe_wrap(Array, dataptr(s), size(s))
unsafe_array(r::RObject{S}) where S<:VectorSxp = unsafe_array(r.p)


# Sxp iterator
IteratorSize(x::Ptr{S}) where S<:Sxp = Base.SizeUnknown()
IteratorEltype(x::Ptr{S}) where S<:Sxp = Base.EltypeUnknown()
pairs(s::Ptr{S}) where S<:Sxp = Pairs(s, Base.OneTo(length(s)))

# RObject iterator
@inline iterate(x::RObject) = iterate(x.p)
@inline iterate(x::RObject, state) = iterate(x.p, state)
IteratorSize(x::RObject) = IteratorSize(x.p)
IteratorEltype(x::RObject) = IteratorEltype(x.p)
pairs(r::RObject{S}) where S<:Sxp = Pairs(r, Base.OneTo(length(r)))

# NilSxp

IteratorSize(x::Ptr{NilSxp}) = Base.HasLength()
iterate(s::Ptr{NilSxp}) = nothing
iterate(s::Ptr{NilSxp}, state) = nothing

# VectorSxp

getindex(r::RObject{S}, I...) where S<:VectorSxp = getindex(sexp(r), I...)
getindex(r::RObject{S}, I::AbstractArray) where S<:VectorSxp = getindex(sexp(r), I)
setindex!(r::RObject{S}, value, keys...) where S<:VectorSxp = setindex!(sexp(r), value, keys...)
setindex!(r::RObject{S}, ::Missing, keys...) where S<:VectorSxp = setindex!(sexp(r), naeltype(S), keys...)

IteratorSize(x::Ptr{S}) where S<:VectorSxp = Base.HasLength()
IteratorEltype(x::Ptr{S}) where S<:VectorSxp = Base.HasEltype()
iterate(s::Ptr{S}) where S<:VectorSxp = iterate(s, 0)
function iterate(s::Ptr{S}, state) where S<:VectorSxp
    state ≥ length(s) && return nothing
    state += 1
    (s[state], state)
end


"""
Set element of a VectorSxp by a label.
"""
function getindex(s::Ptr{S}, label::AbstractString) where S<:VectorSxp
    ls = getnames(s)
    for (i,l) in enumerate(ls)
        if rcopy(String, l) == label
            return s[i]
        end
    end
    throw(BoundsError())
end
getindex(s::Ptr{S}, label::Symbol) where S<:VectorSxp = getindex(s,string(label))

"""
Set element of a VectorSxp by a label.
"""
function setindex!(s::Ptr{S}, value::Ptr{T}, label::AbstractString) where {S<:VectorSxp, T<:Sxp}
    ls = getnames(s)
    for (i,l) in enumerate(ls)
        if rcopy(String, l) == label
            s[i] = value
            return
        end
    end
    throw(BoundsError())
end
setindex!(s::Ptr{S}, value, label::AbstractString) where S<:VectorSxp = setindex!(s, sexp(value), label)
setindex!(s::Ptr{S}, value, label::Symbol) where S<:VectorSxp = setindex!(s, value, string(label))


# VectorAtomicSxp
getindex(s::Ptr{S}, I::Integer) where S<:VectorAtomicSxp = getindex(unsafe_vec(s),I)
getindex(s::Ptr{S}, I::Integer...) where S<:VectorAtomicSxp = getindex(unsafe_array(s),I...)
getindex(s::Ptr{S}, I::AbstractVector) where S<:VectorAtomicSxp = getindex(unsafe_vec(s),I)

function setindex!(s::Ptr{S}, value, I::Integer...) where S<:VectorAtomicSxp
    setindex!(unsafe_array(s), value, I...)
end
function setindex!(s::Ptr{S}, value, I::Integer) where S<:VectorAtomicSxp
    setindex!(unsafe_vec(s), value, I)
end

# VectorList

IteratorEltype(x::RObject{S}) where S<:VectorListSxp = Base.EltypeUnknown()
iterate(s::RObject{S}) where S<:VectorListSxp = iterate(s, 0)
function iterate(s::RObject{S}, state) where S<:VectorListSxp
    state ≥ length(s) && return nothing
    state += 1
    (RObject(s[state]), state)
end

Base.checkbounds(::Type{Bool}, r::RObject{S}, i::Integer) where S<:VectorListSxp =
    1 <= i <= length(r)
Base.checkbounds(r::RObject{S}, i) where S<:VectorListSxp =
    checkbounds(Bool, r, i) ? nothing : throw(BoundsError(r, i))
function getindex(r::RObject{S}, i::Integer) where S<:VectorListSxp
    @boundscheck checkbounds(r, i)
    RObject(getindex(sexp(r), i))
end

# StrSxp

function getindex(s::Ptr{StrSxp}, key::Integer)
    c = ccall((:STRING_ELT, libR), Ptr{CharSxp}, (Ptr{StrSxp}, Cint), s, key-1)
end

function setindex!(s::Ptr{StrSxp}, value::Ptr{CharSxp}, key::Integer)
    1 <= key <= length(s) || throw(BoundsError())
    ccall((:SET_STRING_ELT,libR), Nothing,
          (Ptr{StrSxp},Cptrdiff_t, Ptr{CharSxp}),
          s, key-1, value)
    value
end
function setindex!(s::Ptr{StrSxp}, value::AbstractString, key::Integer)
    setindex!(s,sexp(CharSxp,value),key)
end

# VecSxp and ExprSxp

function getindex(s::Ptr{S}, key::Integer) where S<:Union{VecSxp,ExprSxp}
    sexp(ccall((:VECTOR_ELT, libR), Ptr{UnknownSxp}, (Ptr{S}, Cint), s, key-1))
end

function setindex!(s::Ptr{S}, value::Ptr{T}, key::Integer) where {S<:Union{VecSxp,ExprSxp}, T<:Sxp}
    1 <= key <= length(s) || throw(BoundsError())
    ccall((:SET_VECTOR_ELT,libR), Ptr{T},
          (Ptr{S},Cptrdiff_t, Ptr{T}),
          s, key-1, value)
end
function setindex!(s::Ptr{S}, value, key::Integer) where {S<:Union{VecSxp,ExprSxp}}
    setindex!(s,sexp(value),key)
end


# PairListSxps

cdr(s::Ptr{S}) where S<:PairListSxp = sexp(ccall((:CDR,libR),Ptr{UnknownSxp},(Ptr{S},),s))
car(s::Ptr{S}) where S<:PairListSxp = sexp(ccall((:CAR,libR),Ptr{UnknownSxp},(Ptr{S},),s))
tag(s::Ptr{S}) where S<:PairListSxp = sexp(ccall((:TAG,libR),Ptr{UnknownSxp},(Ptr{S},),s))

function setcar!(s::Ptr{S}, c::Ptr{T}) where {S<:PairListSxp, T<:Sxp}
    ccall((:SETCAR,libR),Ptr{Cvoid},(Ptr{S},Ptr{T}),s,c)
    nothing
end
setcar!(s::Ptr{S}, c::RObject{T}) where {S<:PairListSxp, T<:Sxp} = setcar!(s,sexp(c))

function settag!(s::Ptr{S}, c::Ptr{T}) where {S<:PairListSxp, T<:Sxp}
    ccall((:SET_TAG,libR),Nothing,(Ptr{S},Ptr{T}),s,c)
    nothing
end
settag!(s::Ptr{S}, c::RObject{T}) where {S<:PairListSxp, T<:Sxp} = settag!(s,sexp(c))

function setcdr!(s::Ptr{S}, c::Ptr{T}) where {S<:PairListSxp, T<:Sxp}
    ccall((:SETCDR,libR),Ptr{Cvoid},(Ptr{S},Ptr{T}),s,c)
    nothing
end
setcdr!(s::Ptr{S}, c::RObject{T}) where {S<:PairListSxp, T<:Sxp} = setcdr!(s,sexp(c))

iterate(s::Ptr{S}) where S<:PairListSxp = iterate(s, s)
function iterate(s::Ptr{S}, state) where S<:PairListSxp
    state == sexp(Const.NilValue) && return nothing
    car(state), cdr(state)
end

iterate(s::RObject{S}) where S<:PairListSxp = iterate(s, s.p)
function iterate(s::RObject{S}, state) where S<:PairListSxp
    state == sexp(Const.NilValue) && return nothing
    RObject(car(state)), cdr(state)
end


# iterator for PairListSxp
IteratorSize(x::Pairs{K, V, I, Ptr{S}}) where {K, V, I, S<:PairListSxp} = Base.SizeUnknown()
IteratorEltype(x::Pairs{K, V, I, Ptr{S}}) where {K, V, I, S<:PairListSxp} = Base.EltypeUnknown()
@inline iterate(x::Pairs{K, V, I, Ptr{S}}) where {K, V, I, S<:PairListSxp} = iterate(x, values(x))
@inline function iterate(x::Pairs{K, V, I, Ptr{S}}, state) where {K, V, I, S<:PairListSxp}
    state == sexp(Const.NilValue) && return nothing
    (tag(state), car(state)), cdr(state)
end

IteratorSize(x::Pairs{K, V, I, RObject{S}}) where {K, V, I, S<:PairListSxp} = Base.SizeUnknown()
IteratorEltype(x::Pairs{K, V, I, RObject{S}}) where {K, V, I, S<:PairListSxp} = Base.EltypeUnknown()
@inline iterate(x::Pairs{K, V, I, RObject{S}}) where {K, V, I, S<:PairListSxp} = iterate(x, values(x).p)
@inline function iterate(x::Pairs{K, V, I, RObject{S}}, state) where {K, V, I, S<:PairListSxp}
    state == sexp(Const.NilValue) && return nothing
    (RObject(tag(state)), RObject(car(state))), cdr(state)
end

"extract the i-th element of a PairListSxp"
function getindex(l::Ptr{S},I::Integer) where S<:PairListSxp
    1 ≤ I ≤ length(l) || throw(BoundsError())
    for i in 2:I
        l = cdr(l)
    end
    car(l)
end
getindex(r::RObject{S},I::Integer) where S<:PairListSxp = RObject(getindex(sexp(r),I))

"extract an element from a PairListSxp by label"
function getindex(s::Ptr{S}, label::AbstractString) where S<:PairListSxp
    ls = getnames(s)
    for (i,l) in enumerate(ls)
        if rcopy(String, l) == label
            return s[i]
        end
    end
    throw(BoundsError())
end
getindex(s::Ptr{S}, label::Symbol) where S<:PairListSxp = getindex(s,string(label))
getindex(s::RObject{S}, label) where S<:PairListSxp = RObject(getindex(s.p,label))

"assign value v to the i-th element of a PairListSxp"
function setindex!(l::Ptr{S},v::Ptr{T},I::Integer) where {S<:PairListSxp, T<:Sxp}
    1 ≤ I ≤ length(l) || throw(BoundsError())
    for i in 2:I
        l = cdr(l)
    end
    setcar!(l,v)
end
function setindex!(s::Ptr{S}, value, key::Integer) where S<:PairListSxp
    setindex!(s,sexp(value),key)
end

"""
Set element of a PairListSxp by a label.
"""
function setindex!(s::Ptr{S}, value::Ptr{T}, label::AbstractString) where {S<:PairListSxp, T<:Sxp}
    ls = getnames(s)
    for (i,l) in enumerate(ls)
        if rcopy(String, l) == label
            s[i] = value
            return
        end
    end
    throw(BoundsError())
end
setindex!(s::Ptr{S}, value, label::AbstractString) where S<:PairListSxp = setindex!(s, sexp(value), label)
setindex!(s::Ptr{S}, value, label::Symbol) where S<:PairListSxp = setindex!(s, value, string(label))

# for RObjects
setindex!(r::RObject{S}, value, key) where S<:PairListSxp = setindex!(sexp(r), value, key)


# S4Sxp
"extract an element from a S4Sxp by label"
function getindex(s::Ptr{S4Sxp}, sym::Ptr{SymSxp})
    if ccall((:R_has_slot, libR), Int, (Ptr{S4Sxp}, Ptr{SymSxp}), s, sym) == 1
        return sexp(ccall((:R_do_slot, libR), Ptr{UnknownSxp}, (Ptr{S4Sxp}, Ptr{SymSxp}), s, sym))
    else
        throw(BoundsError())
    end
end
getindex(s::Ptr{S4Sxp}, sym) = getindex(s,sexp(SymSxp, sym))
getindex(s::RObject{S4Sxp}, sym) = RObject(getindex(s.p,sym))

"extract an element from a S4Sxp by label"
function setindex!(s::Ptr{S4Sxp}, value::Ptr{T}, sym::Ptr{SymSxp}) where T<:Sxp
    protect(value)
    try
        t = rcall_p(findNamespace("methods")[:checkSlotAssignment], s, rcopy(String, sym), value)
        sexp(ccall((:R_do_slot_assign, libR), Ptr{UnknownSxp}, (Ptr{S4Sxp}, Ptr{SymSxp}, Ptr{T}), s, sym, t))
    finally
        unprotect(1)
    end
end
setindex!(s::Ptr{S4Sxp}, value, sym) = setindex!(s, sexp(value), sexp(SymSxp, sym))
# for RObjects
setindex!(s::RObject{S4Sxp}, value, sym) = setindex!(sexp(s), value, sym)


"Return a particular attribute of an RObject"
function getattrib(s::Ptr{S}, sym::Ptr{SymSxp}) where S<:Sxp
    sexp(ccall((:Rf_getAttrib,libR),Ptr{UnknownSxp},(Ptr{S},Ptr{SymSxp}),s,sym))
end
getattrib(s::Ptr{S}, sym) where S<:Sxp = getattrib(s,sexp(SymSxp,sym))
getattrib(r::RObject, sym) = RObject(getattrib(r.p,sym))

"Set a particular attribute of an RObject"
function setattrib!(s::Ptr{S},sym::Ptr{SymSxp},t::Ptr{T}) where {S<:Sxp, T<:Sxp}
    ccall((:Rf_setAttrib,libR),Ptr{Cvoid},(Ptr{S},Ptr{SymSxp},Ptr{T}),s,sym,t)
    return nothing
end
setattrib!(s::Ptr{S}, sym, t) where S<:Sxp = setattrib!(s, sexp(SymSxp,sym), sexp(t))
setattrib!(r::RObject, sym, t) = setattrib!(r.p, sym, t)

attributes(s::SxpHead) = sexp(convert(Ptr{SxpHead}, s.attrib))
attributes(s::Sxp) = attributes(s.head)
attributes(s::Ptr{S}) where S<:Sxp = attributes(unsafe_load(s))
attributes(s::RObject) = RObject(attributes(s.p))


"""
Returns the size of an R object.
"""
function size(s::Ptr{S}) where S<:Sxp
    if isFrame(s)
        (length(getattrib(s, Const.RowNamesSymbol)), length(s))
    elseif isArray(s)
        tuple(convert(Array{Int},unsafe_vec(getattrib(s,Const.DimSymbol)))...)
    else
        (length(s),)
    end
end
size(r::RObject) = size(r.p)

"""
Returns the names of an R vector.
"""
getnames(s::Ptr{S}) where S<:Sxp = getattrib(s,Const.NamesSymbol)
getnames(r::RObject) = RObject(getnames(sexp(r)))


"""
Returns the names of an R vector, the result is converted to a Julia symbol array.
"""
names(r::RObject) = rcopy(Vector{Symbol}, getnames(sexp(r)))

"""
Set the names of an R vector.
"""
setnames!(s::Ptr{S}, n::Ptr{StrSxp}) where S<:Sxp = setattrib!(s,Const.NamesSymbol,n)
setnames!(r::RObject, n) = RObject(setnames!(sexp(r),sexp(StrSxp,n)))

"""
Returns the class of an R object.
"""
function getclass(s::Ptr{S}, singleString::Bool=false) where S<:Sxp
    ccall((:R_data_class,libR),Ptr{StrSxp},(Ptr{S},Cint),s,singleString)
end
getclass(s::Ptr{CharSxp}, singleString::Bool=false) = Const.NilValue
getclass(r::RObject, singleString::Bool=false) = RObject(getclass(sexp(r), singleString))


"""
Set the class of an R object.
"""
setclass!(s::Ptr{S},c::Ptr{StrSxp}) where S<:Sxp = setattrib!(s,Const.ClassSymbol,c)
setclass!(r::RObject,c) = RObject(setclass!(sexp(r)),sexp(StrSxp,c))


allocList(n::Int) = ccall((:Rf_allocList,libR),Ptr{ListSxp},(Cint,),n)
allocArray(::Type{S}, n::Integer) where S<:Sxp =
    ccall((:Rf_allocVector,libR),Ptr{S},(Cint,Cptrdiff_t),sexpnum(S),n)

allocArray(::Type{S}, n1::Integer, n2::Integer) where S<:Sxp =
    ccall((:Rf_allocMatrix,libR),Ptr{S},(Cint,Cint,Cint),sexpnum(S),n1,n2)

allocArray(::Type{S}, n1::Integer, n2::Integer, n3::Integer) where S<:Sxp =
    ccall((:Rf_alloc3DArray,libR),Ptr{S},(Cint,Cint,Cint,Cint),sexpnum(S),n1,n2,n3)

function allocArray(::Type{S}, dims::Integer...) where S<:Sxp
    sdims = sexp(RClass{:integer},[dims...])
    ccall((:Rf_allocArray,libR),Ptr{S},(Cint,Ptr{IntSxp}),sexpnum(S),sdims)
end


isnull(s::Ptr{S}) where S<:Sxp = isNull(s)
"""
Check if values correspond to R's NULL object.
"""
isnull(r::RObject) = isnull(r.p)

"""
NA element for each R base class
"""
naeltype(::Type{LglSxp}) = Const.NaInt
naeltype(::Type{IntSxp}) = Const.NaInt
naeltype(::Type{RealSxp}) = Const.NaReal
naeltype(::Type{CplxSxp}) = complex(Const.NaReal)
naeltype(::Type{StrSxp}) = sexp(Const.NaString)
# naeltype(::Type{S}) where S<:Sxp = sexp(Const.NilValue)

naeltype(::Type{RClass{:logical}}) = Const.NaInt
naeltype(::Type{RClass{:integer}}) = Const.NaInt
naeltype(::Type{RClass{:numeric}}) = Const.NaReal
naeltype(::Type{RClass{:complex}}) = complex(Const.NaReal,Const.NaReal)
naeltype(::Type{RClass{:character}}) = sexp(Const.NaString)


# mirror src/main/arithmetic.c
function is_ieee_na(x::Float64)
    @static if reinterpret(UInt32,UInt64[1])[1] == 1  # little endian
        isnan(x) && reinterpret(UInt32,[x])[1] == 0x7a2
    else
        isnan(x) && reinterpret(UInt32,[x])[2] == 0x7a2
    end
end

"""
Check if a value corresponds to R's sentinel NA values.
These function should not be exported.
"""
isNA(x::ComplexF64) = is_ieee_na(real(x)) && is_ieee_na(imag(x))
isNA(x::Float64) = is_ieee_na(x)
isNA(x::Int32) = x == Const.NaInt
isNA(s::Ptr{CharSxp}) = s === sexp(Const.NaString)
isNA(s::Ptr{S}) where S<:VectorSxp = length(s) == 1 ? isNA(s[1]) : false
# all other values are considered as non-NA.
isNA(s::Any) = false

isna(s::Ptr{S}, i::Integer) where S<:VectorSxp = isNA(s[i])
isna(s::Ptr{S}) where S<:VectorSxp = reshape(BitArray([isNA(a) for a in s]), size(s))
"""
Check if the ith member of s correspond to R's NA values.
"""
isna(r::RObject, i::Integer) = isna(r.p, i)
"""
Check if the members of a vector are NA values. Always return a BitArray.
"""
isna(r::RObject) = isna(r.p)

function anyna(s::Ptr{S}) where S<:VectorSxp
    for a in s
        if isNA(a)
            return true
        end
    end
    return false
end
"""
Check if there are any NA values in the vector.
"""
anyna(r::RObject{S}) where S<:VectorSxp = anyna(r.p)


# StrSxp
"""
Determines the encoding of the CharSxp. This is determined by the 'gp' part of the sxpinfo (this is the middle 16 bits).
 * 0x00_0002_00 (bit 1): set of bytes (no known encoding)
 * 0x00_0004_00 (bit 2): Latin-1
 * 0x00_0008_00 (bit 3): UTF-8
 * 0x00_0040_00 (bit 6): ASCII

We only support ASCII and UTF-8.
"""
function isascii(s::CharSxp)
    if s.head.info & 0x00_0040_00 != 0
        return true
    elseif s.head.info & 0x00_0008_00 != 0
        return false
    else
        error("Unsupported string type.")
    end
end
isascii(s::Ptr{CharSxp}) = isascii(unsafe_load(s))
isascii(r::RObject{CharSxp}) = isascii(sexp(r))

function isascii(s::Ptr{StrSxp})
    ind = true
    for c in s
        ind &= isNA(c) || isascii(c)
    end
    return ind
end
isascii(r::RObject{StrSxp}) = isascii(sexp(r))

# EnvSxp

function findVarInFrame(e::Ptr{EnvSxp}, s::Ptr{SymSxp})
    ccall((:Rf_findVarInFrame,libR),Ptr{UnknownSxp},(Ptr{EnvSxp},Ptr{SymSxp}),e,s)
end
findVarInFrame(e, s) = findVarInFrame(sexp(e), sexp(SymSxp, s))

function defineVar(s::Ptr{SymSxp}, v::Ptr{S}, e::Ptr{EnvSxp}) where S<:Sxp
    ccall((:Rf_defineVar,libR),Nothing,(Ptr{SymSxp},Ptr{S},Ptr{EnvSxp}),s,v,e)
    nothing
end
defineVar(s, v, p) = defineVar(sexp(SymSxp, s), sexp(v), sexp(p))

"extract the value of symbol s in the environment e"
function getindex(e::Ptr{EnvSxp},s::Ptr{SymSxp})
    v = findVarInFrame(e, s)
    v == sexp(Const.UnboundValue) && throw(BoundsError())
    sexp(v)
end
getindex(e::Ptr{EnvSxp},s) = getindex(e,sexp(SymSxp,s))
getindex(e::RObject{EnvSxp},s) = RObject(getindex(sexp(e),s))

"assign value v to symbol s in the environment e"
function setindex!(e::Ptr{EnvSxp},v::Ptr{S},s::Ptr{StrSxp}) where S<:Sxp
    # `Rf_defineVar` is unsafe to use if the binding is locked.
    # However, `setVarInFrame` is not exported. `base::assign` is
    # an available alternative.
    rcall_p(Const.BaseNamespace["assign"], s, v, envir = e)
end
function setindex!(e::Ptr{EnvSxp},v,s)
    nprotect = 0
    try
        sv = protect(sexp(v))
        nprotect += 1
        ss = protect(sexp(RClass{:character},s))
        nprotect += 1
        setindex!(e,sv,ss)
    finally
        unprotect(nprotect)
    end
end
setindex!(e::RObject{EnvSxp}, v, s) = setindex!(sexp(e), v, s)

"""
    newEnvironment([env])

Create a new environment which extends environment `env` (`globalEnv` by default).
"""
function newEnvironment(env::Ptr{EnvSxp})
    ccall((:Rf_NewEnvironment,libR),Ptr{EnvSxp},
            (Ptr{NilSxp},Ptr{NilSxp},Ptr{EnvSxp}),sexp(Const.NilValue),sexp(Const.Const.NilValue),env)
end
newEnvironment(env::RObject{EnvSxp}) = newEnvironment(sexp(env))
newEnvironment() = newEnvironment(globalEnv)


"find namespace by name of the namespace, it is not error tolerant."
function findNamespace(str::String)
    ccall((:R_FindNamespace,libR),Ptr{EnvSxp}, (Ptr{StrSxp},), sexp(str))
end

"get namespace by name of the namespace. It is safer to be used than findNamespace as it checks bound."
getNamespace(str::String) = reval(rlang(RCall.Const.BaseNamespace["getNamespace"], str))


"Set the variable .Last.value to a given value"
function set_last_value(s::Ptr{S}) where S<:Sxp
    ccall((:SET_SYMVALUE,libR),Nothing,(Ptr{SymSxp},Ptr{UnknownSxp}),sexp(Const.LastvalueSymbol),s)
    nothing
end
