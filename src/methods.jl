"""
The R NAMED property, represented by 2 bits in the info field. This can take
values 0,1 or 2, corresponding to whether it is bound to 0,1 or 2 or more
symbols. See
http://cran.r-project.org/doc/manuals/r-patched/R-exts.html#Named-objects-and-copying
"""
function bound{S<:Sxp}(s::Ptr{S})
    u = unsafe_load(convert(Ptr{UnknownSxp},s))
    (u.info >>> 6) & 0x03
end


"""
Sxp methods for `length` return the R length.

`Rf_xlength` handles Sxps that are not vector-like and R's
"long vectors", which have a negative value for the `length` member.
"""
length{S<:Sxp}(s::Ptr{S}) =
    Int(ccall((:Rf_xlength,libR),Cptrdiff_t,(Ptr{S},),s))
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
        $sym{S<:Sxp}(s::Ptr{S}) = ccall(($(string("Rf_",sym)),libR),Bool,(Ptr{SxpPtrInfo},),s)
        $sym(r::RObject) = $sym(r.p)
    end
end

"""
Pointer to start of the data array in a SEXPREC. Corresponds to DATAPTR C macro.
"""
dataptr{S<:VectorSxp}(s::Ptr{S}) = convert(Ptr{eltype(S)}, s+voffset[])

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
unsafe_vec{S<:VectorSxp}(s::Ptr{S}) = unsafe_wrap(Array, dataptr(s), length(s))
unsafe_vec{S<:VectorSxp}(r::RObject{S}) = unsafe_vec(r.p)

"""
The same as `unsafe_vec`, except returns an appropriately sized array.
"""
unsafe_array{S<:VectorSxp}(s::Ptr{S}) =  unsafe_wrap(Array, dataptr(s), size(s))
unsafe_array{S<:VectorSxp}(r::RObject{S}) = unsafe_array(r.p)

# used in indexing
start(s::Ptr{NilSxp}) = 0
next(s::Ptr{NilSxp},state) = (s, state)
done(s::Ptr{NilSxp},state) = true

start(r::RObject{NilSxp}) = 0
next(r::RObject{NilSxp},state) = (r, state)
done(r::RObject{NilSxp},state) = true


"""
Indexing into `VectorSxp` types uses Julia indexing into the `vec` result,
except for `StrSxp` and the `VectorListSxp` types, which must apply `sexp`
to the `Ptr{Void}` obtained by indexing into the `vec` result.
"""
getindex{S<:VectorAtomicSxp}(s::Ptr{S}, I::Integer) = getindex(unsafe_vec(s),I)
getindex{S<:VectorAtomicSxp}(s::Ptr{S}, I::Integer...) = getindex(unsafe_array(s),I...)
getindex{S<:VectorAtomicSxp}(s::Ptr{S}, I::AbstractVector) = getindex(unsafe_vec(s),I)

getindex{S<:VectorListSxp}(s::Ptr{S}, I::Integer) = sexp(getindex(unsafe_vec(s),I))
getindex{S<:VectorListSxp}(s::Ptr{S}, I::Integer...) = sexp(getindex(unsafe_array(s),I...))
getindex{S<:VectorListSxp}(s::Ptr{S}, I::AbstractVector) = map(sexp, getindex(unsafe_vec(s),I))

"""
String indexing finds the first element with the matching name
"""
function getindex{S<:VectorSxp}(s::Ptr{S}, label::AbstractString)
    ls = getnames(s)
    for (i,l) in enumerate(ls)
        if rcopy(l) == label
            return s[i]
        end
    end
    throw(BoundsError())
end
getindex{S<:VectorSxp}(s::Ptr{S}, label::Symbol) = getindex(s,string(label))

getindex{S<:VectorAtomicSxp}(r::RObject{S}, I...) = getindex(sexp(r), I...)
getindex{S<:VectorAtomicSxp}(r::RObject{S}, I::AbstractArray) = getindex(sexp(r), I)

getindex{S<:VectorListSxp}(r::RObject{S}, I...) = RObject(getindex(sexp(r), I...))
getindex{S<:VectorListSxp}(r::RObject{S}, I::AbstractArray) = map(RObject,getindex(sexp(r),I))


function setindex!{S<:VectorAtomicSxp}(s::Ptr{S}, value, I::Integer...)
    setindex!(unsafe_array(s), value, I...)
end
function setindex!{S<:VectorAtomicSxp}(s::Ptr{S}, value, I::Integer)
    setindex!(unsafe_vec(s), value, I)
end
function setindex!(s::Ptr{StrSxp}, value::Ptr{CharSxp}, key::Integer)
    1 <= key <= length(s) || throw(BoundsError())
    ccall((:SET_STRING_ELT,libR), Void,
          (Ptr{StrSxp},Cptrdiff_t, Ptr{CharSxp}),
          s, key-1, value)
    value
end
function setindex!(s::Ptr{StrSxp}, value::AbstractString, key::Integer)
    setindex!(s,sexp(CharSxp,value),key)
end

function setindex!{S<:Union{VecSxp,ExprSxp},T<:Sxp}(s::Ptr{S}, value::Ptr{T}, key::Integer)
    1 <= key <= length(s) || throw(BoundsError())
    ccall((:SET_VECTOR_ELT,libR), Ptr{T},
          (Ptr{S},Cptrdiff_t, Ptr{T}),
          s, key-1, value)
end
function setindex!{S<:Union{VecSxp,ExprSxp}}(s::Ptr{S}, value, key::Integer)
    setindex!(s,sexp(value),key)
end
"""
Set element of a VectorSxp by a label.
"""
function setindex!{S<:VectorSxp, T<:Sxp}(s::Ptr{S}, value::Ptr{T}, label::AbstractString)
    ls = getnames(s)
    for (i,l) in enumerate(ls)
        if rcopy(l) == label
            s[i] = value
            return
        end
    end
    throw(BoundsError())
end
setindex!{S<:VectorSxp, T<:Sxp}(s::Ptr{S}, value::Ptr{T}, label::Symbol) = setindex!(s, value, string(label))
setindex!{S<:VectorSxp}(s::Ptr{S}, value, label) = setindex!(s, sexp(value), label)

setindex!{S<:VectorSxp}(r::RObject{S}, value, keys...) = setindex!(sexp(r), value, keys...)




start{S<:VectorSxp}(s::Ptr{S}) = 0
next{S<:VectorSxp}(s::Ptr{S},state) = (state += 1;(s[state],state))
done{S<:VectorSxp}(s::Ptr{S},state) = state ≥ length(s)

start{S<:VectorSxp}(s::RObject{S}) = start(s.p)
next{S<:VectorSxp}(s::RObject{S},state) = next(s.p, state)
done{S<:VectorSxp}(s::RObject{S},state) = done(s.p, state)

# PairListSxps

cdr{S<:PairListSxp}(s::Ptr{S}) = sexp(ccall((:CDR,libR),Ptr{UnknownSxp},(Ptr{S},),s))
car{S<:PairListSxp}(s::Ptr{S}) = sexp(ccall((:CAR,libR),Ptr{UnknownSxp},(Ptr{S},),s))
tag{S<:PairListSxp}(s::Ptr{S}) = sexp(ccall((:TAG,libR),Ptr{UnknownSxp},(Ptr{S},),s))

function setcar!{S<:PairListSxp,T<:Sxp}(s::Ptr{S}, c::Ptr{T})
    ccall((:SETCAR,libR),Ptr{Void},(Ptr{S},Ptr{T}),s,c)
    nothing
end
setcar!{S<:PairListSxp,T<:Sxp}(s::Ptr{S}, c::RObject{T}) = setcar!(s,sexp(c))

function settag!{S<:PairListSxp,T<:Sxp}(s::Ptr{S}, c::Ptr{T})
    ccall((:SET_TAG,libR),Void,(Ptr{S},Ptr{T}),s,c)
    nothing
end
settag!{S<:PairListSxp,T<:Sxp}(s::Ptr{S}, c::RObject{T}) = settag!(s,sexp(c))

function setcdr!{S<:PairListSxp,T<:Sxp}(s::Ptr{S}, c::Ptr{T})
    ccall((:SETCDR,libR),Ptr{Void},(Ptr{S},Ptr{T}),s,c)
    nothing
end
setcdr!{S<:PairListSxp,T<:Sxp}(s::Ptr{S}, c::RObject{T}) = setcdr!(s,sexp(c))



start{S<:PairListSxp}(s::Ptr{S}) = s
function next{S<:PairListSxp,T<:PairListSxp}(s::Ptr{S},state::Ptr{T})
    t = tag(state)
    c = car(state)
    (t,c), cdr(state)
end
done{S<:PairListSxp,T<:PairListSxp}(s::Ptr{S},state::Ptr{T}) = state == sexp(Const.NilValue)

start{S<:PairListSxp}(s::RObject{S}) = start(s.p)
next{S<:PairListSxp}(s::RObject{S},state) = next(s.p, state)
done{S<:PairListSxp}(s::RObject{S},state) = done(s.p, state)


"extract the i-th element of a PairListSxp"
function getindex{S<:PairListSxp}(l::Ptr{S},I::Integer)
    1 ≤ I ≤ length(l) || throw(BoundsError())
    for i in 2:I
        l = cdr(l)
    end
    car(l)
end
getindex{S<:PairListSxp}(r::RObject{S},I::Integer) = RObject(getindex(sexp(r),I))

"extract an element from a PairListSxp by label"
function getindex{S<:PairListSxp}(s::Ptr{S}, label::AbstractString)
    ls = getnames(s)
    for (i,l) in enumerate(ls)
        if rcopy(l) == label
            return s[i]
        end
    end
    throw(BoundsError())
end
getindex{S<:PairListSxp}(s::Ptr{S}, label::Symbol) = getindex(s,string(label))
getindex{S<:PairListSxp}(s::RObject{S}, label) = RObject(getindex(s.p,label))


"assign value v to the i-th element of a PairListSxp"
function setindex!{S<:PairListSxp,T<:Sxp}(l::Ptr{S},v::Ptr{T},I::Integer)
    1 ≤ I ≤ length(l) || throw(BoundsError())
    for i in 2:I
        l = cdr(l)
    end
    setcar!(l,v)
end
function setindex!{S<:PairListSxp}(s::Ptr{S}, value, key::Integer)
    setindex!(s,sexp(value),key)
end

"""
Set element of a PairListSxp by a label.
"""
function setindex!{S<:PairListSxp, T<:Sxp}(s::Ptr{S}, value::Ptr{T}, label::AbstractString)
    ls = getnames(s)
    for (i,l) in enumerate(ls)
        if rcopy(l) == label
            s[i] = value
            return
        end
    end
    throw(BoundsError())
end
setindex!{S<:PairListSxp, T<:Sxp}(s::Ptr{S}, value::Ptr{T}, label::Symbol) = setindex!(s, value, string(label))
setindex!{S<:PairListSxp}(s::Ptr{S}, value, label) = setindex!(s, sexp(value), label)

setindex!{S<:PairListSxp}(r::RObject{S}, value, label) = setindex!(sexp(r), value, label)


# S4Sxp
"extract an element from a S4Sxp by label"
function getindex(s::Ptr{S4Sxp}, sym::Ptr{SymSxp})
    if ccall((:R_has_slot, libR), Int, (Ptr{S4Sxp}, Ptr{SymSxp}), s, sym) == 1
        return sexp(ccall((:R_do_slot, libR), Ptr{UnknownSxp}, (Ptr{S4Sxp}, Ptr{SymSxp}), s, sym))
    else
        throw(BoundsError())
    end
end
getindex(s::Ptr{S4Sxp}, sym::RObject{SymSxp}) = getindex(s,sexp(sym))
getindex(s::Ptr{S4Sxp}, sym::Symbol) = getindex(s,sexp(SymSxp, sym))
getindex(s::Ptr{S4Sxp}, sym::AbstractString) = getindex(s,sexp(SymSxp, sym))
getindex(s::RObject{S4Sxp}, sym) = RObject(getindex(s.p,sym))

"extract an element from a S4Sxp by label"
function setindex!{T<:Sxp}(s::Ptr{S4Sxp}, value::Ptr{T}, sym::Ptr{SymSxp})
    protect(value)
    try
        t = rcall_p(findNamespace("methods")[:checkSlotAssignment], s, rcopy(String, sym), value)
        sexp(ccall((:R_do_slot_assign, libR), Ptr{UnknownSxp}, (Ptr{S4Sxp}, Ptr{SymSxp}, Ptr{T}), s, sym, t))
    finally
        unprotect(1)
    end
end
setindex!(s::Ptr{S4Sxp}, value, sym::RObject{SymSxp}) = setindex!(s, sexp(value), sexp(SymSxp, sym))
setindex!(s::Ptr{S4Sxp}, value, sym::Symbol) = setindex!(s, sexp(value), sexp(SymSxp, sym))
setindex!(s::Ptr{S4Sxp}, value, sym::AbstractString) = setindex!(s, sexp(value), sexp(SymSxp, sym))
setindex!(s::RObject{S4Sxp}, value, sym) = setindex!(s.p, value, sym)


"Return a particular attribute of an RObject"
function getattrib{S<:Sxp}(s::Ptr{S}, sym::Ptr{SymSxp})
    sexp(ccall((:Rf_getAttrib,libR),Ptr{UnknownSxp},(Ptr{S},Ptr{SymSxp}),s,sym))
end
getattrib{S<:Sxp}(s::Ptr{S}, sym::RObject{SymSxp}) = getattrib(s,sexp(sym))
getattrib{S<:Sxp}(s::Ptr{S}, sym::Symbol) = getattrib(s,sexp(SymSxp,sym))
getattrib{S<:Sxp}(s::Ptr{S}, sym::AbstractString) = getattrib(s,sexp(SymSxp,sym))

getattrib(r::RObject, sym) = RObject(getattrib(r.p,sym))

"Set a particular attribute of an RObject"
function setattrib!{S<:Sxp,T<:Sxp}(s::Ptr{S},sym::Ptr{SymSxp},t::Ptr{T})
    ccall((:Rf_setAttrib,libR),Ptr{Void},(Ptr{S},Ptr{SymSxp},Ptr{T}),s,sym,t)
    return nothing
end
setattrib!{S<:Sxp,T<:Sxp}(s::Ptr{S},sym::RObject{SymSxp},t::Ptr{T}) = setattrib!(s,sexp(sym),t)
setattrib!{S<:Sxp,T<:Sxp}(s::Ptr{S},sym::Symbol,t::Ptr{T}) = setattrib!(s,sexp(SymSxp,sym),t)
setattrib!{S<:Sxp,T<:Sxp}(s::Ptr{S},sym::AbstractString,t::Ptr{T}) = setattrib!(s,sexp(SymSxp,sym),t)
setattrib!{S<:Sxp}(s::Ptr{S},sym,t) = setattrib!(s,sym,sexp(t))

setattrib!(r::RObject, sym, t) = setattrib!(r.p, sym, t)

attributes(s::SxpHead) = sexp(s.attrib)
attributes(s::Sxp) = attributes(s.head)
attributes{S<:Sxp}(s::Ptr{S}) = attributes(unsafe_load(s))
attributes{S<:Sxp}(s::RObject{S}) = RObject(attributes(s.p))


function size{S<:Sxp}(s::Ptr{S})
    isArray(s) || return (length(s),)
    tuple(convert(Array{Int},unsafe_vec(getattrib(s,Const.DimSymbol)))...)
end
size(r::RObject) = size(sexp(r))


"""
Returns the names of an R vector.
"""
getnames{S<:Sxp}(s::Ptr{S}) = getattrib(s,Const.NamesSymbol)
getnames(r::RObject) = RObject(getnames(sexp(r)))


"""
Returns the names of an R vector, the result is converted to a Julia symbol array.
"""
names(r::RObject) = rcopy(Vector{Symbol}, getnames(sexp(r)))

"""
Set the names of an R vector.
"""
setnames!{S<:Sxp}(s::Ptr{S}, n::Ptr{StrSxp}) = setattrib!(s,Const.NamesSymbol,n)
setnames!(r::RObject,n) = RObject(setnames!(sexp(r),sexp(StrSxp,n)))

"""
Returns the class of an R object.
"""
getclass{S<:Sxp}(s::Ptr{S}) = getattrib(s,Const.ClassSymbol)
getclass(r::RObject) = RObject(getclass(sexp(r)))


"""
Set the class of an R object.
"""
setclass!{S<:Sxp}(s::Ptr{S},c::Ptr{StrSxp}) = setattrib!(s,Const.ClassSymbol,c)
setclass!(r::RObject,c) = RObject(setclass!(sexp(r)),sexp(StrSxp,c))


allocList(n::Int) = ccall((:Rf_allocList,libR),Ptr{ListSxp},(Cint,),n)
allocArray{S<:Sxp}(::Type{S}, n::Integer) =
    ccall((:Rf_allocVector,libR),Ptr{S},(Cint,Cptrdiff_t),sexpnum(S),n)

allocArray{S<:Sxp}(::Type{S}, n1::Integer, n2::Integer) =
    ccall((:Rf_allocMatrix,libR),Ptr{S},(Cint,Cint,Cint),sexpnum(S),n1,n2)

allocArray{S<:Sxp}(::Type{S}, n1::Integer, n2::Integer, n3::Integer) =
    ccall((:Rf_alloc3DArray,libR),Ptr{S},(Cint,Cint,Cint,Cint),sexpnum(S),n1,n2,n3)

function allocArray{S<:Sxp}(::Type{S}, dims::Integer...)
    sdims = sexp(IntSxp,[dims...])
    ccall((:Rf_allocArray,libR),Ptr{S},(Cint,Ptr{IntSxp}),sexpnum(S),sdims)
end


isnull{S<:Sxp}(s::Ptr{S}) = isNull(s)
"""
Check if values correspond to R's NULL object.
"""
isnull{S<:Sxp}(r::RObject{S}) = isnull(r.p)

"""
NA element for each type
"""
naeltype(::Type{LglSxp}) = Const.NaInt
naeltype(::Type{IntSxp}) = Const.NaInt
naeltype(::Type{RealSxp}) = Const.NaReal
naeltype(::Type{CplxSxp}) = complex(Const.NaReal,Const.NaReal)
naeltype(::Type{StrSxp}) = sexp(Const.NaString)
naeltype(::Type{VecSxp}) = sexp(LglSxp,Const.NaInt) # used for setting
naeltype{S<:Sxp}(::Type{S}) = sexp(LglSxp,Const.NaInt)

"""
Check if a value corresponds to R's sentinel NA values.
These function should not be exported.
"""
isNA(x::Complex128) = real(x) === Const.NaReal && imag(x) === Const.NaReal
isNA(x::Float64) = x === Const.NaReal
isNA(x::Int32) = x == Const.NaInt
isNA(s::Ptr{CharSxp}) = s === sexp(Const.NaString)
isNA{S<:VectorSxp}(s::Ptr{S}) = length(s) == 1 ? isNA(s[1]) : false
# all other values are consided as non-NA.
isNA(s::Any) = false

isna{S<:VectorSxp}(s::Ptr{S}, i::Integer) = isNA(s[i])
isna{S<:VectorSxp}(s::Ptr{S}) = reshape(BitArray([isNA(a) for a in s]), size(s))
"""
Check if the ith member of s coorespond to R's NA values.
"""
isna(r::RObject, i::Integer) = isna(r.p, i)
"""
Check if the members of a vector are NA values. Always return a BitArray.
"""
isna(r::RObject) = isna(r.p)

function anyna{S<:VectorSxp}(s::Ptr{S})
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
anyna{S<:VectorSxp}(r::RObject{S}) = anyna(r.p)


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

function defineVar{S<:Sxp}(s::Ptr{SymSxp}, v::Ptr{S}, e::Ptr{EnvSxp})
    ccall((:Rf_defineVar,libR),Void,(Ptr{SymSxp},Ptr{S},Ptr{EnvSxp}),s,v,e)
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
function setindex!{S<:Sxp}(e::Ptr{EnvSxp},v::Ptr{S},s::Ptr{StrSxp})
    # defineVar(s, v, e)
    # Rf_defineVar is unsafe to use if the binding is locked.
    # base::assign is a safer alternative.
    rcall_p(Const.BaseNamespace["assign"], s, v, envir = e)
end
function setindex!(e::Ptr{EnvSxp},v,s)
    nprotect = 0
    try
        sv = protect(sexp(v))
        nprotect += 1
        ss = protect(sexp(StrSxp,s))
        nprotect += 1
        setindex!(e,sv,ss)
    finally
        unprotect(nprotect)
    end
end
setindex!(e::RObject{EnvSxp},v,s) = setindex!(sexp(e),v,s)

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
function set_last_value{S<:Sxp}(s::Ptr{S})
    ccall((:SET_SYMVALUE,libR),Void,(Ptr{SymSxp},Ptr{UnknownSxp}),sexp(Const.LastvalueSymbol),s)
    nothing
end
