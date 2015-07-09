typealias SxpInfo UInt32

@doc "R SEXPREC header: a pointer to this is used for unknown types."->
immutable SxpHead <: SEXPREC
    info::SxpInfo
    attrib::Ptr{SxpHead}
    gc_next::Ptr{SxpHead}
    gc_prev::Ptr{SxpHead}
end

@doc "R NULL value"->
immutable NilSxp <: SEXPREC   # type tag 0
    head::SxpHead
end


@doc "R pairs (cons) list cell"->
immutable ListSxp <: SEXPREC  # type tag 2
    head::SxpHead
    car::Ptr{SxpHead}
    cdr::Ptr{SxpHead}
    tag::Ptr{SxpHead}
end

@doc "R function closure"->
immutable ClosSxp <: SEXPREC  # type tag 3
    head::SxpHead
    formals::Ptr{ListSxp}
    body::Ptr{SxpHead}
    env::Ptr{SxpHead}
end

@doc "R environment"->
immutable EnvSxp <: SEXPREC  # type tag 4
    head::SxpHead
    frame::Ptr{SxpHead}
    enclos::Ptr{SxpHead}
    hashtab::Ptr{SxpHead}
end

@doc "R promise"->
immutable PromSxp <: SEXPREC  # type tag 5
    head::SxpHead
    value::Ptr{SxpHead}
    expr::Ptr{SxpHead}
    env::Ptr{SxpHead}
end

@doc "R function call"->
immutable LangSxp <: SEXPREC  # type tag 6
    head::SxpHead
    car::Ptr{SxpHead}
    cdr::Ptr{SxpHead}
    tag::Ptr{SxpHead}
end

@doc "R special function"->
immutable SpecialSxp <: SEXPREC  # type tag 7
    head::SxpHead
end

@doc "R built-in function"->
immutable BuiltinSxp <: SEXPREC  # type tag 8
    head::SxpHead
end

@doc "R character string"->
immutable CharSxp <: SEXPREC     # type tag 9
    head::SxpHead
    length::Cint
    truelength::Cint
end

@doc "R symbol"->
immutable SymSxp <: SEXPREC   # type tag 1
    head::SxpHead
    name::Ptr{CharSxp}
    value::Ptr{SxpHead}
    internal::Ptr{SxpHead}
end

@doc "R logical vector"->
immutable LglSxp <: SEXPREC     # type tag 10
    head::SxpHead
    length::Cint
    truelength::Cint
end

@doc "R integer vector"->
immutable IntSxp <: SEXPREC     # type tag 13
    head::SxpHead
    length::Cint
    truelength::Cint
end

@doc "R real vector"->
immutable RealSxp <: SEXPREC    # type tag 14
    head::SxpHead
    length::Cint
    truelength::Cint
end

@doc "R complex vector"->
immutable CplxSxp <: SEXPREC    # type tag 15
    head::SxpHead
    length::Cint
    truelength::Cint
end

@doc "R vector of character strings"->
immutable StrSxp <: SEXPREC     # type tag 16
    head::SxpHead
    length::Cint
    truelength::Cint
end

@doc "R dot-dot-dot object"->
immutable DotSxp <: SEXPREC     # type tag 17
    head::SxpHead
end

@doc "R \"any\" object"->
immutable AnySxp <: SEXPREC     # type tag 18
    head::SxpHead
end

@doc "R list (i.e. Array{Any,1})"->
immutable VecSxp <: SEXPREC     # type tag 19
    head::SxpHead
    length::Cint
    truelength::Cint
end

@doc "R expression vector"->
immutable ExprSxp <: SEXPREC    # type tag 20
    head::SxpHead
    length::Cint
    truelength::Cint
end

@doc "R byte code"->
immutable BcodeSxp <: SEXPREC   # type tag 21
    head::SxpHead
end

@doc "R external pointer"->
immutable ExtPtrSxp <: SEXPREC  # type tag 22
    head::SxpHead
    ptr::Ptr{Void}
    prot::Ptr{Void}
    tag::Ptr{SxpHead}
end

@doc "R weak reference"->
immutable WeakRefSxp <: SEXPREC  # type tag 23
    head::SxpHead
end

@doc "R byte vector"->
immutable RawSxp <: SEXPREC      # type tag 24
    head::SxpHead
    length::Cint
    truelength::Cint
end

@doc "R S4 object"->
immutable S4Sxp <: SEXPREC      # type tag 25
    head::SxpHead
end

@doc "Vector types in R"->
typealias RVector Union(CharSxp,LglSxp,IntSxp,RealSxp,CplxSxp,StrSxp,VecSxp,ExprSxp,RawSxp)

typealias VectorAtomic Union(LglSxp,IntSxp,RealSxp,CplxSxp,RawSxp,CharSxp)

typealias VectorList Union(VecSxp,StrSxp,ExprSxp)

typealias PairList Union(NilSxp,ListSxp,LangSxp)

typealias Primitive Union(BuiltinSxp,SpecialSxp)

typealias RFunction Union(ClosSxp,BuiltinSxp,SpecialSxp)

@doc """
Element types of R vectors.
"""->
eltype(::Type{LglSxp}) = Cint
eltype(::Type{IntSxp}) = Cint
eltype(::Type{RealSxp}) = Float64
eltype(::Type{CplxSxp}) = Complex128
eltype(::Type{CharSxp}) = UInt8
eltype(::Type{RawSxp}) = UInt8

eltype(::Type{StrSxp}) = Ptr{CharSxp}
eltype(::Type{VecSxp}) = Ptr{SxpHead}
eltype(::Type{ExprSxp}) = Ptr{SxpHead}



@doc """
The general user-facing type for R objects. It is protected from garbage collection until being finalized by Julia
"""->
type RObject{S<:SEXPREC}
    p::Ptr{S}
    function RObject(p::Ptr{S})
        preserve(p)
        r = new(p)
        finalizer(r, release)
        r
    end
end
RObject{S<:SEXPREC}(p::Ptr{S}) = RObject{S}(p)
RObject(x::RObject) = x
RObject(x) = RObject(sexp(x))


# convert{T}(::Type{T}, r::RObject) = convert(T,r.p)

@doc """
Prevent garbage collection of an R object. Object can be released via `release`.

This is slower than `protect`, as it requires searching an internal list, but
more flexible.
"""->
preserve{S<:SEXPREC}(p::Ptr{S}) = ccall((:R_PreserveObject,libR), Void, (Ptr{S},), p)

@doc """
Release object that has been gc protected by `preserve`.
"""->
release{S<:SEXPREC}(p::Ptr{S}) = ccall((:R_ReleaseObject,libR),Void,(Ptr{S},),p)
release{S<:SEXPREC}(r::RObject{S}) = release(r.p)

@doc """ 

Stack-based protection of garbage collection of R objects. Objects are
released via `unprotect`. Returns the same pointer, allowing inline use.

This is faster than `preserve`, but more restrictive. Really only useful
inside functions.
"""->
protect{S<:SEXPREC}(p::Ptr{S}) = ccall((:Rf_protect,libR), Ptr{S}, (Ptr{S},), p)

@doc """
Release last `n` objects gc-protected by `protect`.
"""->
unprotect(n::Integer) = ccall((:Rf_unprotect,libR), Void, (Cint,), n)

@doc "vector of R SEXPREC types"->
const typs = [NilSxp,SymSxp,ListSxp,ClosSxp,EnvSxp,PromSxp,LangSxp,SpecialSxp,BuiltinSxp,
              CharSxp,LglSxp,Void,Void,IntSxp,RealSxp,CplxSxp,StrSxp,DotSxp,AnySxp,
              VecSxp,ExprSxp,BcodeSxp,ExtPtrSxp,WeakRefSxp,RawSxp,S4Sxp]

for (i,T) in enumerate(typs)
    if T != Void
        @eval sexpnum(::Type{$T}) = $(i-1)
    end
end


@doc """
Convert a `Ptr{SxpHead}` to a `Ptr{S}`, where `S` is the appropriate SEXPREC.

The SEXPTYPE, determined from the trailing 5 bits of the first 32-bit word, is a 0-based
index into the `typs` vector.
"""->
function sexp(p::Ptr{SxpHead})
    head = unsafe_load(p)
    typ = head.info & 0x1f
    0 ≤ typ ≤ 10 || 13 ≤ typ ≤ 25 || error("Unknown SEXPTYPE $typ")
    styp = typs[typ+1]
    convert(Ptr{styp},p)
end
sexp{S<:SEXPREC}(s::Ptr{S}) = s
sexp(r::RObject) = r.p

