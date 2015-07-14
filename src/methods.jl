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
function named{S<:Sxp}(s::Ptr{S})
    u = unsafe_load(convert(UnknownSxpPtr,s))
    (u.info >>> 6) & 0x03
end


@doc """
Sxp methods for `length` return the R length.

`Rf_xlength` handles Sxps that are not vector-like and R's
"long vectors", which have a negative value for the `length` member.
"""->
length{S<:Sxp}(s::Ptr{S}) =
    @compat Int(ccall((:Rf_xlength,libR),Cptrdiff_t,(Ptr{S},),s))
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

@doc """
Represent the contents of an VectorSxp type as a `Vector`.

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
"""->
unsafe_vec{S<:VectorSxp}(s::Ptr{S}) = pointer_to_array(convert(Ptr{eltype(S)}, s+voffset), length(s))
unsafe_vec{S<:VectorSxp}(r::RObject{S}) = unsafe_vec(r.p)


@doc """
Indexing into `VectorSxp` types uses Julia indexing into the `vec` result,
except for `StrSxp` and the `VectorListSxp` types, which must apply `sexp`
to the `Ptr{Void}` obtained by indexing into the `vec` result.
"""->
getindex{S<:VectorSxp}(s::Ptr{S}, I::Union(Real,AbstractVector)) = getindex(unsafe_vec(s),I)
getindex(s::Ptr{VecSxp}, I::Union(Real,AbstractVector)) = sexp(getindex(unsafe_vec(s),I))
getindex(s::Ptr{ExprSxp}, I::Union(Real,AbstractVector)) = sexp(getindex(unsafe_vec(s),I))

@doc """
String indexing finds the first element with the matching name
"""->
function getindex{S<:VectorSxp}(s::Ptr{S}, label::String)
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
getindex{S<:VectorSxp}(s::Ptr{S}, label::Symbol) = getindex(s,string(label))

function setindex!{S<:VectorAtomicSxp}(s::Ptr{S}, value, key)
    setindex!(unsafe_vec(s), value, key)
end
function setindex!(s::Ptr{StrSxp}, value::CharSxpPtr, key::Integer)
    1 <= key <= length(s) || throw(BoundsError())
    ccall((:SET_STRING_ELT,libR), Void,
          (Ptr{StrSxp},Cptrdiff_t, CharSxpPtr),
          s, key-1, value)
    return value
end
setindex!(s::Ptr{StrSxp}, value::String, key::Integer) =
    setindex!(s,sexp(CharSxp,value),key)

function setindex!{S<:Union(VecSxp,ExprSxp),T<:Sxp}(s::Ptr{S}, value::Ptr{T}, key::Integer)
    1 <= key <= length(s) || throw(BoundsError())
    ccall((:SET_VECTOR_ELT,libR), Ptr{T},
          (Ptr{S},Cptrdiff_t, Ptr{T}),
          s, key-1, value)
end
setindex!{S<:Union(VecSxp,ExprSxp)}(s::Ptr{S}, value, key::Integer) =
    setindex!(s,sexp(value),key)


getindex{S<:VectorAtomicSxp}(r::RObject{S}, I) = getindex(r.p, I)
getindex{S<:VectorAtomicSxp}(r::RObject{S}, I::AbstractArray) = getindex(r.p, I)

getindex(r::RObject, I) = RObject(getindex(r.p,I))
getindex(r::RObject, I::AbstractArray) = map(RObject,getindex(r.p,I))

setindex!(r::RObject, value::RObject, key) = setindex!(r.p,value.p,key)




start{S<:VectorSxp}(s::Ptr{S}) = 0
next{S<:VectorSxp}(s::Ptr{S},state) = (state += 1;(s[state],state))
done{S<:VectorSxp}(s::Ptr{S},state) = state ≥ length(s)



# PairListSxps

cdr{S<:PairListSxp}(s::Ptr{S}) = sexp(ccall((:CDR,libR),UnknownSxpPtr,(Ptr{S},),s))
car{S<:PairListSxp}(s::Ptr{S}) = sexp(ccall((:CAR,libR),UnknownSxpPtr,(Ptr{S},),s))
tag{S<:PairListSxp}(s::Ptr{S}) = sexp(ccall((:TAG,libR),UnknownSxpPtr,(Ptr{S},),s))

setcar!{S<:PairListSxp,T<:Sxp}(s::Ptr{S}, c::Ptr{T}) = (ccall((:SETCAR,libR),Ptr{Void},(Ptr{S},Ptr{T}),s,c); return nothing)
settag!{S<:PairListSxp,T<:Sxp}(s::Ptr{S}, c::Ptr{T}) = ccall((:SET_TAG,libR),Void,(Ptr{S},Ptr{T}),s,c)


start{S<:PairListSxp}(s::Ptr{S}) = s
function next{S<:PairListSxp,T<:PairListSxp}(s::Ptr{S},state::Ptr{T})
    t = tag(state)
    c = car(state)
    (t,c), cdr(state)
end
done{S<:PairListSxp,T<:PairListSxp}(s::Ptr{S},state::Ptr{T}) = state == rNilValue

@doc "extract the i-th element of LangSxp l"->
function getindex{S<:PairListSxp}(l::Ptr{S},I::Integer)
    1 ≤ I ≤ length(l) || throw(BoundsError())
    for i in 2:I
        l = cdr(l)
    end
    car(l)
end

@doc "assign value v to the i-th element of LangSxp l"->
function setindex!{S<:PairListSxp,T<:Sxp}(l::Ptr{S},v::Ptr{T},I::Integer)
    1 ≤ I ≤ length(l) || throw(BoundsError())
    for i in 2:I
        l = cdr(l)
    end
    setcar!(l,v)
end



function getAttrib{S<:Sxp}(s::Ptr{S}, sym::Ptr{SymSxp})
    sexp(ccall((:Rf_getAttrib,libR),UnknownSxpPtr,(Ptr{S},Ptr{SymSxp}),s,sym))
end
getAttrib{S<:Sxp}(s::Ptr{S}, sym::Symbol) = getAttrib(s,sexp(SymSxp,sym))
getAttrib{S<:Sxp}(s::Ptr{S}, sym::String) = getAttrib(s,sexp(SymSxp,sym))

getAttrib(r::RObject, sym) = RObject(getAttrib(r.p,sym))

function setAttrib!{S<:Sxp,T<:Sxp}(s::Ptr{S},sym::Ptr{SymSxp},t::Ptr{T})
    ccall((:Rf_setAttrib,libR),Ptr{Void},(Ptr{S},Ptr{SymSxp},Ptr{T}),s,sym,t)
    return nothing
end
setAttrib!{S<:Sxp,T<:Sxp}(s::Ptr{S},sym::Symbol,t::Ptr{T}) = setAttrib!(s,sexp(SymSxp,sym),t)
setAttrib!{S<:Sxp,T<:Sxp}(s::Ptr{S},sym::String,t::Ptr{T}) = setAttrib!(s,sexp(SymSxp,sym),t)
setAttrib!{S<:Sxp}(s::Ptr{S},sym,t) = setAttrib!(s,sym,sexp(t))

setAttrib!(r::RObject, sym, t) = setAttrib!(r.p, sym, t)

attributes(s::SxpHead) = sexp(s.attrib)
attributes(s::Sxp) = attributes(s.head)
attributes{S<:Sxp}(s::Ptr{S}) = attributes(unsafe_load(s))


function size{S<:Sxp}(s::Ptr{S})
    isArray(s) || return (length(s),)
    tuple(convert(Array{Int},unsafe_vec(getAttrib(s,rDimSymbol)))...)
end
size(r::RObject) = r


@doc """
Returns the names of an R vector.
"""->
getNames{S<:VectorSxp}(s::Ptr{S}) = getAttrib(s,rNamesSymbol)
getNames(r::RObject) = RObject(getNames(sexp(r)))




@doc """
Set the names of an R vector.
"""->
setNames!{S<:VectorSxp}(s::Ptr{S},n::Ptr{StrSxp}) = setAttrib!(s,rNamesSymbol,n)
setNames!(r::RObject,n) = RObject(setNames!(sexp(r)),sexp(StrSxp,n))

allocList(n::Int) = ccall((:Rf_allocList,libR),Ptr{ListSxp},(Cint,),n)
allocArray{S<:Sxp}(::Type{S}, n::Integer) =
    ccall((:Rf_allocVector,libR),Ptr{S},(Cint,Cptrdiff_t),sexpnum(S),n)

allocArray{S<:Sxp}(::Type{S}, n1::Integer, n2::Integer) =
    ccall((:Rf_allocMatrix,libR),Ptr{S},(Cint,Cint,Cint),sexpnum(S),n1,n2)

allocArray{S<:Sxp}(::Type{S}, n1::Integer, n2::Integer, n3::Integer) =
    ccall((:Rf_alloc3DArray,libR),Ptr{S},(Cint,Cint,Cint,Cint),sexpnum(S),n1,n2,3)

function allocArray{S<:Sxp}(::Type{S}, dims::Integer...)
    sdims = sexp(IntSxp,[dims...])
    ccall((:Rf_allocArray,libR),Ptr{S},(Cint,Ptr{IntSxp}),sexpnum(S),sdims)
end


@doc """
NA element for each type
"""->
NAel(::Type{LglSxp}) = rNaInt
NAel(::Type{IntSxp}) = rNaInt
NAel(::Type{RealSxp}) = rNaReal
NAel(::Type{CplxSxp}) = complex(rNaReal,rNaReal)
NAel(::Type{StrSxp}) = rNaString
NAel(::Type{VecSxp}) = sexp(LglSxp,rNaInt) # used for setting


@doc """
Check if values correspond to R's sentinel NA values.
"""->
isNA(x::Complex128) = real(x) === rNaReal && imag(x) === rNaReal
isNA(x::Float64) = x === rNaReal
isNA(x::Int32) = x == rNaInt
isNA(a::AbstractArray) = reshape(bitpack([isNA(aa) for aa in a]),size(a))
isNA(s::CharSxpPtr) = s === rNaString

# this doesn't allow us to check VecSxp s
function isNA{S<:VectorSxp}(s::Ptr{S})
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
function anyNA{S<:VectorSxp}(s::Ptr{S})
    for i in s
        if isNA(s)
            return true
        end
    end
    return false
end



# EnvSxp

@doc "extract the value of symbol s in the environment e"->
function getindex(e::Ptr{EnvSxp},s::Ptr{SymSxp})
    v = ccall((:Rf_findVarInFrame,libR),UnknownSxpPtr,(Ptr{EnvSxp},Ptr{SymSxp}),e,s)
    v == rUnboundValue && error("$s is not defined in the environment")
    sexp(v)
end


@doc "assign value v to symbol s in the environment e"->
function setindex!{S<:Sxp}(e::Ptr{EnvSxp},v::Ptr{S},s::Ptr{SymSxp})
    # This should be done more carefully.  First check for the symbol in the
    # frame.  If it is defined call Rf_setVar, otherwise call Rf_defineVar.
    # As it stands this segfaults if the symbol is bound in, say, the base
    # environment.
    ccall((:Rf_setVar,libR),Void,(Ptr{SymSxp},Ptr{S},Ptr{EnvSxp}),s,v,e)
end
function setindex!(e::Ptr{EnvSxp},v,s::Symbol)
    sv = protect(sexp(v))
    ss = protect(sexp(s))
    setindex!(e,sv,ss)
    unprotect(2)
end
