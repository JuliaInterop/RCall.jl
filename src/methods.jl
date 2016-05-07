"""
The R NAMED property, represented by 2 bits in the info field. This can take
values 0,1 or 2, corresponding to whether it is bound to 0,1 or 2 or more
symbols. See
http://cran.r-project.org/doc/manuals/r-patched/R-exts.html#Named-objects-and-copying
"""
function bound{S<:Sxp}(s::Ptr{S})
    u = unsafe_load(convert(UnknownSxpPtr,s))
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
            :isNumber,:isObject,:isOrdered,:isPairListSxp,:isPrimitiveSxp,
            :isReal,:isS4,:isString,:isTs,:isUnordered,:isUnsorted,
            :isUserBinop,:isValidString,:isValidStringF,:isVector,
            :isVectorAtomicSxp,:isVectorizable,:isVectorListSxp)
    @eval begin
        $sym{S<:Sxp}(s::Ptr{S}) = ccall(($(string("Rf_",sym)),libR),Bool,(Ptr{SxpPtrInfo},),s)
        $sym(r::RObject) = $sym(r.p)
    end
end

"Check whether an R variable is a factor variable"
isFactor

"Check whether an R variable is an ordered factor variable"
isOrdered


const voffset = Ref{UInt}()

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
unsafe_vec{S<:VectorSxp}(s::Ptr{S}) = pointer_to_array(dataptr(s), length(s))
unsafe_vec{S<:VectorSxp}(r::RObject{S}) = unsafe_vec(r.p)

"""
The same as `unsafe_vec`, except returns an appropriately sized array.
"""
unsafe_array{S<:VectorSxp}(s::Ptr{S}) =  pointer_to_array(dataptr(s), size(s))
unsafe_array{S<:VectorSxp}(r::RObject{S}) = unsafe_array(r.p)



"""
Indexing into `VectorSxp` types uses Julia indexing into the `vec` result,
except for `StrSxp` and the `VectorListSxp` types, which must apply `sexp`
to the `Ptr{Void}` obtained by indexing into the `vec` result.
"""
getindex{S<:VectorAtomicSxp}(s::Ptr{S}, I::Real) = getindex(unsafe_vec(s),I)
getindex{S<:VectorAtomicSxp}(s::Ptr{S}, I::AbstractVector) = getindex(unsafe_vec(s),I)
getindex{S<:VectorAtomicSxp}(s::Ptr{S}, I::Real...) = getindex(unsafe_array(s),I...)

getindex{S<:VectorListSxp}(s::Ptr{S}, I::Real) = sexp(getindex(unsafe_vec(s),I))
getindex{S<:VectorListSxp}(s::Ptr{S}, I::AbstractVector) = sexp(getindex(unsafe_vec(s),I))
getindex{S<:VectorListSxp}(s::Ptr{S}, I::Real...) = sexp(getindex(unsafe_array(s),I...))

"""
String indexing finds the first element with the matching name
"""
function getindex{S<:VectorSxp}(s::Ptr{S}, label::AbstractString)
    ls = unsafe_vec(getNames(s))
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


function setindex!{S<:VectorAtomicSxp}(s::Ptr{S}, value, I...)
    setindex!(unsafe_array(s), value, I...)
end
function setindex!{S<:VectorAtomicSxp}(s::Ptr{S}, value, I)
    setindex!(unsafe_vec(s), value, I)
end
function setindex!(s::Ptr{StrSxp}, value::CharSxpPtr, key::Integer)
    1 <= key <= length(s) || throw(BoundsError())
    ccall((:SET_STRING_ELT,libR), Void,
          (Ptr{StrSxp},Cptrdiff_t, CharSxpPtr),
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

setindex!(r::RObject, value, keys...) = setindex!(sexp(r), value, keys...)




start{S<:VectorSxp}(s::Ptr{S}) = 0
next{S<:VectorSxp}(s::Ptr{S},state) = (state += 1;(s[state],state))
done{S<:VectorSxp}(s::Ptr{S},state) = state ≥ length(s)



# PairListSxps

cdr{S<:PairListSxp}(s::Ptr{S}) = sexp(ccall((:CDR,libR),UnknownSxpPtr,(Ptr{S},),s))
car{S<:PairListSxp}(s::Ptr{S}) = sexp(ccall((:CAR,libR),UnknownSxpPtr,(Ptr{S},),s))
tag{S<:PairListSxp}(s::Ptr{S}) = sexp(ccall((:TAG,libR),UnknownSxpPtr,(Ptr{S},),s))

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

"extract the i-th element of LangSxp l"
function getindex{S<:PairListSxp}(l::Ptr{S},I::Integer)
    1 ≤ I ≤ length(l) || throw(BoundsError())
    for i in 2:I
        l = cdr(l)
    end
    car(l)
end

getindex{S<:PairListSxp}(r::RObject{S},I::Integer) = RObject(getindex(sexp(r),I))

"assign value v to the i-th element of LangSxp l"
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


"Return a particular attribute of an RObject"
function getAttrib{S<:Sxp}(s::Ptr{S}, sym::Ptr{SymSxp})
    sexp(ccall((:Rf_getAttrib,libR),UnknownSxpPtr,(Ptr{S},Ptr{SymSxp}),s,sym))
end
getAttrib{S<:Sxp}(s::Ptr{S}, sym::RObject{SymSxp}) = getAttrib(s,sexp(sym))
getAttrib{S<:Sxp}(s::Ptr{S}, sym::Symbol) = getAttrib(s,sexp(SymSxp,sym))
getAttrib{S<:Sxp}(s::Ptr{S}, sym::AbstractString) = getAttrib(s,sexp(SymSxp,sym))

getAttrib(r::RObject, sym) = RObject(getAttrib(r.p,sym))

"Set a particular attribute of an RObject"
function setAttrib!{S<:Sxp,T<:Sxp}(s::Ptr{S},sym::Ptr{SymSxp},t::Ptr{T})
    ccall((:Rf_setAttrib,libR),Ptr{Void},(Ptr{S},Ptr{SymSxp},Ptr{T}),s,sym,t)
    return nothing
end
setAttrib!{S<:Sxp,T<:Sxp}(s::Ptr{S},sym::RObject{SymSxp},t::Ptr{T}) = setAttrib!(s,sexp(sym),t)
setAttrib!{S<:Sxp,T<:Sxp}(s::Ptr{S},sym::Symbol,t::Ptr{T}) = setAttrib!(s,sexp(SymSxp,sym),t)
setAttrib!{S<:Sxp,T<:Sxp}(s::Ptr{S},sym::AbstractString,t::Ptr{T}) = setAttrib!(s,sexp(SymSxp,sym),t)
setAttrib!{S<:Sxp}(s::Ptr{S},sym,t) = setAttrib!(s,sym,sexp(t))

setAttrib!(r::RObject, sym, t) = setAttrib!(r.p, sym, t)

attributes(s::SxpHead) = sexp(s.attrib)
attributes(s::Sxp) = attributes(s.head)
attributes{S<:Sxp}(s::Ptr{S}) = attributes(unsafe_load(s))


function size{S<:Sxp}(s::Ptr{S})
    isArray(s) || return (length(s),)
    tuple(convert(Array{Int},unsafe_vec(getAttrib(s,Const.DimSymbol)))...)
end
size(r::RObject) = size(sexp(r))


"""
Returns the names of an R vector.
"""
getNames{S<:VectorSxp}(s::Ptr{S}) = getAttrib(s,Const.NamesSymbol)
getNames(r::RObject) = RObject(getNames(sexp(r)))

"""
Set the names of an R vector.
"""
setNames!{S<:VectorSxp}(s::Ptr{S}, n::Ptr{StrSxp}) = setAttrib!(s,Const.NamesSymbol,n)
setNames!(r::RObject,n) = RObject(setNames!(sexp(r),sexp(StrSxp,n)))

"""
Returns the class of an R object.
"""
getClass{S<:Sxp}(s::Ptr{S}) = getAttrib(s,Const.ClassSymbol)
getClass(r::RObject) = RObject(getClass(sexp(r)))


"""
Set the class of an R object.
"""
setClass!{S<:Sxp}(s::Ptr{S},c::Ptr{StrSxp}) = setAttrib!(s,Const.ClassSymbol,c)
setClass!(r::RObject,c) = RObject(setClass!(sexp(r)),sexp(StrSxp,c))



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


"""
NA element for each type
"""
NAel(::Type{LglSxp}) = Const.NaInt
NAel(::Type{IntSxp}) = Const.NaInt
NAel(::Type{RealSxp}) = Const.NaReal
NAel(::Type{CplxSxp}) = complex(Const.NaReal,Const.NaReal)
NAel(::Type{StrSxp}) = sexp(Const.NaString)
NAel(::Type{VecSxp}) = sexp(LglSxp,Const.NaInt) # used for setting


"""
Check if values correspond to R's sentinel NA values.
"""
isNA(x::Complex128) = real(x) === Const.NaReal && imag(x) === Const.NaReal
isNA(x::Float64) = x === Const.NaReal
isNA(x::Int32) = x == Const.NaInt
isNA(a::AbstractArray) = reshape(bitpack([isNA(aa) for aa in a]),size(a))
isNA(s::CharSxpPtr) = s === sexp(Const.NaString)

# this doesn't allow us to check VecSxp s
function isNA{S<:VectorSxp}(s::Ptr{S})
    b = BitArray(size(s)...)
    for (i,e) in enumerate(s)
        b[i] = isNA(e)
    end
    b
end

isNA(r::RObject) = isNA(r.p)


"""
Check if there are any NA values in the vector.
"""
function anyNA{S<:VectorSxp}(s::Ptr{S})
    for i in s
        if isNA(i)
            return true
        end
    end
    return false
end
anyNA{S<:VectorSxp}(r::RObject{S}) = anyNA(r.p)


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
isascii(s::CharSxpPtr) = isascii(unsafe_load(s))
isascii(r::RObject{CharSxp}) = isascii(sexp(r))

function isascii(s::StrSxpPtr)
    ind = true
    for c in s
        ind &= isNA(c) || isascii(c)
    end
    return ind
end
isascii(r::RObject{StrSxp}) = isascii(sexp(r))

# EnvSxp

"extract the value of symbol s in the environment e"
function getindex(e::Ptr{EnvSxp},s::Ptr{SymSxp})
    v = ccall((:Rf_findVarInFrame,libR),UnknownSxpPtr,(Ptr{EnvSxp},Ptr{SymSxp}),e,s)
    v == sexp(Const.UnboundValue) && error("$s is not defined in the environment")
    sexp(v)
end
getindex(e::Ptr{EnvSxp},s) = getindex(e,sexp(SymSxp,s))
getindex(e::RObject{EnvSxp},s) = RObject(getindex(sexp(e),s))


"assign value v to symbol s in the environment e"
function setindex!{S<:Sxp}(e::Ptr{EnvSxp},v::Ptr{S},s::Ptr{SymSxp})
    # This should be done more carefully.  First check for the symbol in the
    # frame.  If it is defined call Rf_setVar, otherwise call Rf_defineVar.
    # As it stands this segfaults if the symbol is bound in, say, the base
    # environment.
    ccall((:Rf_defineVar,libR),Void,(Ptr{SymSxp},Ptr{S},Ptr{EnvSxp}),s,v,e)
end
function setindex!(e::Ptr{EnvSxp},v,s)
    nprotect = 0
    try
        sv = protect(sexp(v))
        nprotect += 1
        ss = protect(sexp(SymSxp,s))
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
function findNamespace(str::ByteString)
    ccall((:R_FindNamespace,libR),Ptr{EnvSxp}, (Ptr{StrSxp},), sexp(str))
end

"get namespace by name of the namespace. It is safer to be used than findNamespace as it checks bound."
getNamespace(str::ByteString) = reval(rlang_p(RCall.Const.BaseNamespace["getNamespace"], str))
