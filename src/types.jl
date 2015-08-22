@doc """
R symbolic expression (`SxpPtr`): these are represented by a pointer to a
symbolic expression record (`Sxp`).
"""->
abstract Sxp # SEXPREC
typealias SxpPtr{S<:Sxp} Ptr{S} # SEXP

typealias SxpPtrInfo UInt32 # sxpinfo_struct

@doc "R Sxp header: a pointer to this is used for unknown types."->
immutable SxpHead <: Sxp # SEXPREC_HEADER
    info::SxpPtrInfo
    attrib::Ptr{SxpHead}
    gc_next::Ptr{SxpHead}
    gc_prev::Ptr{SxpHead}
end
typealias UnknownSxpPtr Ptr{SxpHead}

@doc "R NULL value"->
immutable NilSxp <: Sxp   # type tag 0
    head::SxpHead
end
typealias NilSxpPtr Ptr{NilSxp}

@doc "R pairs (cons) list cell"->
immutable ListSxp <: Sxp  # type tag 2
    head::SxpHead
    car::UnknownSxpPtr
    cdr::UnknownSxpPtr
    tag::UnknownSxpPtr
end
typealias ListSxpPtr Ptr{ListSxp}

@doc "R function closure"->
immutable ClosSxp <: Sxp  # type tag 3
    head::SxpHead
    formals::ListSxpPtr
    body::UnknownSxpPtr
    env::UnknownSxpPtr
end
typealias ClosSxpPtr Ptr{ClosSxp}

@doc "R environment"->
immutable EnvSxp <: Sxp  # type tag 4
    head::SxpHead
    frame::UnknownSxpPtr
    enclos::UnknownSxpPtr
    hashtab::UnknownSxpPtr
end
typealias EnvSxpPtr Ptr{EnvSxp}

@doc "R promise"->
immutable PromSxp <: Sxp  # type tag 5
    head::SxpHead
    value::UnknownSxpPtr
    expr::UnknownSxpPtr
    env::UnknownSxpPtr
end
typealias PromSxpPtr Ptr{PromSxp}

@doc "R function call"->
immutable LangSxp <: Sxp  # type tag 6
    head::SxpHead
    car::UnknownSxpPtr
    cdr::UnknownSxpPtr
    tag::UnknownSxpPtr
end
typealias LangSxpPtr Ptr{LangSxp}

@doc "R special function"->
immutable SpecialSxp <: Sxp  # type tag 7
    head::SxpHead
end
typealias SpecialSxpPtr Ptr{SpecialSxp}

@doc "R built-in function"->
immutable BuiltinSxp <: Sxp  # type tag 8
    head::SxpHead
end
typealias BuiltinSxpPtr Ptr{BuiltinSxp}

@doc "R character string"->
immutable CharSxp <: Sxp     # type tag 9
    head::SxpHead
    length::Cint
    truelength::Cint
end
typealias CharSxpPtr Ptr{CharSxp}

@doc "R symbol"->
immutable SymSxp <: Sxp   # type tag 1
    head::SxpHead
    name::CharSxpPtr
    value::UnknownSxpPtr
    internal::UnknownSxpPtr
end
typealias SymSxpPtr Ptr{SymSxp}

@doc "R logical vector"->
immutable LglSxp <: Sxp     # type tag 10
    head::SxpHead
    length::Cint
    truelength::Cint
end
typealias LglSxpPtr Ptr{LglSxp}

@doc "R integer vector"->
immutable IntSxp <: Sxp     # type tag 13
    head::SxpHead
    length::Cint
    truelength::Cint
end
typealias IntSxpPtr Ptr{IntSxp}

@doc "R real vector"->
immutable RealSxp <: Sxp    # type tag 14
    head::SxpHead
    length::Cint
    truelength::Cint
end
typealias RealSxpPtr Ptr{RealSxp}

@doc "R complex vector"->
immutable CplxSxp <: Sxp    # type tag 15
    head::SxpHead
    length::Cint
    truelength::Cint
end
typealias CplxSxpPtr Ptr{CplxSxp}

@doc "R vector of character strings"->
immutable StrSxp <: Sxp     # type tag 16
    head::SxpHead
    length::Cint
    truelength::Cint
end
typealias StrSxpPtr Ptr{StrSxp}

@doc "R dot-dot-dot object"->
immutable DotSxp <: Sxp     # type tag 17
    head::SxpHead
end
typealias DotSxpPtr Ptr{DotSxp}

@doc "R \"any\" object"->
immutable AnySxp <: Sxp     # type tag 18
    head::SxpHead
end
typealias AnySxpPtr Ptr{AnySxp}

@doc "R list (i.e. Array{Any,1})"->
immutable VecSxp <: Sxp     # type tag 19
    head::SxpHead
    length::Cint
    truelength::Cint
end
typealias VecSxpPtr Ptr{VecSxp}

@doc "R expression vector"->
immutable ExprSxp <: Sxp    # type tag 20
    head::SxpHead
    length::Cint
    truelength::Cint
end
typealias ExprSxpPtr Ptr{ExprSxp}

@doc "R byte code"->
immutable BcodeSxp <: Sxp   # type tag 21
    head::SxpHead
end
typealias BcodeSxpPtr Ptr{BcodeSxp}

@doc "R external pointer"->
immutable ExtPtrSxp <: Sxp  # type tag 22
    head::SxpHead
    ptr::Ptr{Void}
    prot::Ptr{Void}
    tag::UnknownSxpPtr
end
typealias ExtPtrSxpPtr Ptr{ExtPtrSxp}

@doc "R weak reference"->
immutable WeakRefSxp <: Sxp  # type tag 23
    head::SxpHead
end
typealias WeakRefSxpPtr Ptr{WeakRefSxp}

@doc "R byte vector"->
immutable RawSxp <: Sxp      # type tag 24
    head::SxpHead
    length::Cint
    truelength::Cint
end
typealias RawSxpPtr Ptr{RawSxp}

@doc "R S4 object"->
immutable S4Sxp <: Sxp      # type tag 25
    head::SxpHead
end
typealias S4SxpPtr Ptr{S4Sxp}



@doc "Vector types in R"->
typealias VectorSxp Union(CharSxp,LglSxp,IntSxp,RealSxp,CplxSxp,StrSxp,VecSxp,ExprSxp,RawSxp)
typealias VectorSxpPtr{S<:VectorSxp} Ptr{S}

typealias VectorAtomicSxp Union(LglSxp,IntSxp,RealSxp,CplxSxp,RawSxp,CharSxp)
typealias VectorAtomicSxpPtr{S<:VectorAtomicSxp} Ptr{S}

typealias VectorNumericSxp Union(LglSxp,IntSxp,RealSxp,CplxSxp)
typealias VectorNumericSxpPtr{S<:VectorNumericSxp} Ptr{S}

typealias VectorListSxp Union(VecSxp,StrSxp,ExprSxp)
typealias VectorListSxpPtr{S<:VectorListSxp} Ptr{S}

typealias PairListSxp Union(NilSxp,ListSxp,LangSxp)
typealias PairListSxpPtr{S<:PairListSxp} Ptr{S}

typealias PrimitiveSxp Union(BuiltinSxp,SpecialSxp)
typealias PrimitiveSxpPtr{S<:PrimitiveSxp} Ptr{S}

typealias FunctionSxp Union(ClosSxp,BuiltinSxp,SpecialSxp)
typealias FunctionSxpPtr{S<:FunctionSxp} Ptr{S}

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
eltype(::Type{VecSxp}) = UnknownSxpPtr
eltype(::Type{ExprSxp}) = UnknownSxpPtr





@doc """
An `RObject` is a Julia wrapper for an R object (known as an "S-expression" or "SEXP"). It is stored as a pointer which is protected from the R garbage collector, until the `RObject` itself is finalized by Julia. The parameter is the type of the S-expression.

When called with a Julia object as an argument, a corresponding R object is constructed.

```julia
julia> RObject(1)
RObject{IntSxp}
[1] 1

julia> RObject(1:3)
RObject{IntSxp}
[1] 1 2 3

julia> RObject(1.0:3.0)
RObject{RealSxp}
[1] 1 2 3
```
"""->
type RObject{S<:Sxp}
    p::Ptr{S}
    function RObject(p::Ptr{S})
        preserve(p)
        r = new(p)
        finalizer(r, release)
        r
    end
    # SymSxps are not garbage collected, so preserve not necessary.
    RObject(p::Ptr{SymSxp}) = new(p)
end
RObject{S<:Sxp}(p::Ptr{S}) = RObject{S}(p)
RObject(x::RObject) = x
RObject(x) = RObject(sexp(x))


# convert{T}(::Type{T}, r::RObject) = convert(T,r.p)

@doc """
Prevent garbage collection of an R object. Object can be released via `release`.

This is slower than `protect`, as it requires searching an internal list, but
more flexible.
"""->
preserve{S<:Sxp}(p::Ptr{S}) = ccall((:R_PreserveObject,libR), Void, (Ptr{S},), p)

@doc """
Release object that has been gc protected by `preserve`.
"""->
release{S<:Sxp}(p::Ptr{S}) = ccall((:R_ReleaseObject,libR),Void,(Ptr{S},),p)
release{S<:Sxp}(r::RObject{S}) = release(r.p)

@doc """
Stack-based protection of garbage collection of R objects. Objects are
released via `unprotect`. Returns the same pointer, allowing inline use.

This is faster than `preserve`, but more restrictive. Really only useful
inside functions.
"""->
protect{S<:Sxp}(p::Ptr{S}) = ccall((:Rf_protect,libR), Ptr{S}, (Ptr{S},), p)

@doc """
Release last `n` objects gc-protected by `protect`.
"""->
unprotect(n::Integer) = ccall((:Rf_unprotect,libR), Void, (Cint,), n)

@doc """
The SEXPTYPE number of a `Sxp`

Determined from the trailing 5 bits of the first 32-bit word. Is
a 0-based index into the `info` field of a `SxpHead`.
"""->
sexpnum(h::SxpHead) = h.info & 0x1f
sexpnum(p::SxpPtr) = sexpnum(unsafe_load(p))

@doc "vector of R Sxp types"->
const typs = [NilSxp,SymSxp,ListSxp,ClosSxp,EnvSxp,
              PromSxp,LangSxp,SpecialSxp,BuiltinSxp,CharSxp,
              LglSxp,Void,Void,IntSxp,RealSxp,
              CplxSxp,StrSxp,DotSxp,AnySxp,VecSxp,
              ExprSxp,BcodeSxp,ExtPtrSxp,WeakRefSxp,RawSxp,
              S4Sxp]

for (i,T) in enumerate(typs)
    if T != Void
        @eval sexpnum(::Type{$T}) = $(i-1)
    end
end


@doc """
Convert a `UnknownSxpPtr` to an approptiate `SxpPtr`.
"""->
function sexp(p::UnknownSxpPtr)
    typ = sexpnum(p)
    0 ≤ typ ≤ 10 || 13 ≤ typ ≤ 25 || error("Unknown SEXPTYPE $typ")
    styp = typs[typ+1]
    convert(Ptr{styp},p)
end
sexp(s::SxpPtr) = s
sexp(r::RObject) = r.p

