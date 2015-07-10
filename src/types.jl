@doc """
R symbolic expression (`Sxp`): these are represented by a pointer to a
symbolic expression record (`SxpRec`).
"""->
abstract SxpRec # SEXPREC
typealias Sxp{S<:SxpRec} Ptr{S} # SEXP

typealias SxpInfo UInt32 # sxpinfo_struct

@doc "R SxpRec header: a pointer to this is used for unknown types."->
immutable SxpRecHead <: SxpRec # SEXPREC_HEADER
    info::SxpInfo
    attrib::Ptr{SxpRecHead}
    gc_next::Ptr{SxpRecHead}
    gc_prev::Ptr{SxpRecHead}
end

@doc "R NULL value"->
immutable NilSxpRec <: SxpRec   # type tag 0
    head::SxpRecHead
end
typealias NilSxp Ptr{NilSxpRec}

@doc "R pairs (cons) list cell"->
immutable ListSxpRec <: SxpRec  # type tag 2
    head::SxpRecHead
    car::Ptr{SxpRecHead}
    cdr::Ptr{SxpRecHead}
    tag::Ptr{SxpRecHead}
end
typealias ListSxp Ptr{ListSxpRec}

@doc "R function closure"->
immutable ClosSxpRec <: SxpRec  # type tag 3
    head::SxpRecHead
    formals::Ptr{ListSxpRec}
    body::Ptr{SxpRecHead}
    env::Ptr{SxpRecHead}
end
typealias ClosSxp Ptr{ClosSxpRec}

@doc "R environment"->
immutable EnvSxpRec <: SxpRec  # type tag 4
    head::SxpRecHead
    frame::Ptr{SxpRecHead}
    enclos::Ptr{SxpRecHead}
    hashtab::Ptr{SxpRecHead}
end
typealias EnvSxp Ptr{EnvSxpRec}

@doc "R promise"->
immutable PromSxpRec <: SxpRec  # type tag 5
    head::SxpRecHead
    value::Ptr{SxpRecHead}
    expr::Ptr{SxpRecHead}
    env::Ptr{SxpRecHead}
end
typealias PromSxp Ptr{PromSxpRec}

@doc "R function call"->
immutable LangSxpRec <: SxpRec  # type tag 6
    head::SxpRecHead
    car::Ptr{SxpRecHead}
    cdr::Ptr{SxpRecHead}
    tag::Ptr{SxpRecHead}
end
typealias LangSxp Ptr{LangSxpRec}

@doc "R special function"->
immutable SpecialSxpRec <: SxpRec  # type tag 7
    head::SxpRecHead
end
typealias SpecialSxp Ptr{SpecialSxpRec}

@doc "R built-in function"->
immutable BuiltinSxpRec <: SxpRec  # type tag 8
    head::SxpRecHead
end
typealias BuiltinSxp Ptr{BuiltinSxpRec}

@doc "R character string"->
immutable CharSxpRec <: SxpRec     # type tag 9
    head::SxpRecHead
    length::Cint
    truelength::Cint
end
typealias CharSxp Ptr{CharSxpRec}

@doc "R symbol"->
immutable SymSxpRec <: SxpRec   # type tag 1
    head::SxpRecHead
    name::Ptr{CharSxpRec}
    value::Ptr{SxpRecHead}
    internal::Ptr{SxpRecHead}
end
typealias SymSxp Ptr{SymSxpRec}

@doc "R logical vector"->
immutable LglSxpRec <: SxpRec     # type tag 10
    head::SxpRecHead
    length::Cint
    truelength::Cint
end
typealias LglSxp Ptr{LglSxpRec}

@doc "R integer vector"->
immutable IntSxpRec <: SxpRec     # type tag 13
    head::SxpRecHead
    length::Cint
    truelength::Cint
end
typealias IntSxp Ptr{IntSxpRec}

@doc "R real vector"->
immutable RealSxpRec <: SxpRec    # type tag 14
    head::SxpRecHead
    length::Cint
    truelength::Cint
end
typealias RealSxp Ptr{RealSxpRec}

@doc "R complex vector"->
immutable CplxSxpRec <: SxpRec    # type tag 15
    head::SxpRecHead
    length::Cint
    truelength::Cint
end
typealias CplxSxp Ptr{CplxSxpRec}

@doc "R vector of character strings"->
immutable StrSxpRec <: SxpRec     # type tag 16
    head::SxpRecHead
    length::Cint
    truelength::Cint
end
typealias StrSxp Ptr{StrSxpRec}

@doc "R dot-dot-dot object"->
immutable DotSxpRec <: SxpRec     # type tag 17
    head::SxpRecHead
end
typealias DotSxp Ptr{DotSxpRec}

@doc "R \"any\" object"->
immutable AnySxpRec <: SxpRec     # type tag 18
    head::SxpRecHead
end
typealias AnySxp Ptr{AnySxpRec}

@doc "R list (i.e. Array{Any,1})"->
immutable VecSxpRec <: SxpRec     # type tag 19
    head::SxpRecHead
    length::Cint
    truelength::Cint
end
typealias VecSxp Ptr{VecSxpRec}

@doc "R expression vector"->
immutable ExprSxpRec <: SxpRec    # type tag 20
    head::SxpRecHead
    length::Cint
    truelength::Cint
end
typealias ExprSxp Ptr{ExprSxpRec}

@doc "R byte code"->
immutable BcodeSxpRec <: SxpRec   # type tag 21
    head::SxpRecHead
end
typealias BcodeSxp Ptr{BcodeSxpRec}

@doc "R external pointer"->
immutable ExtPtrSxpRec <: SxpRec  # type tag 22
    head::SxpRecHead
    ptr::Ptr{Void}
    prot::Ptr{Void}
    tag::Ptr{SxpRecHead}
end
typealias ExtPtrSxp Ptr{ExtPtrSxpRec}

@doc "R weak reference"->
immutable WeakRefSxpRec <: SxpRec  # type tag 23
    head::SxpRecHead
end
typealias WeakRefSxp Ptr{WeakRefSxpRec}

@doc "R byte vector"->
immutable RawSxpRec <: SxpRec      # type tag 24
    head::SxpRecHead
    length::Cint
    truelength::Cint
end
typealias RawSxp Ptr{RawSxpRec}

@doc "R S4 object"->
immutable S4SxpRec <: SxpRec      # type tag 25
    head::SxpRecHead
end
typealias S4Sxp Ptr{S4SxpRec}



@doc "Vector types in R"->
typealias VectorSxpRec Union(CharSxpRec,LglSxpRec,IntSxpRec,RealSxpRec,CplxSxpRec,StrSxpRec,VecSxpRec,ExprSxpRec,RawSxpRec)
typealias VectorSxp{S<:VectorSxpRec} Ptr{S}

typealias VectorAtomicSxpRec Union(LglSxpRec,IntSxpRec,RealSxpRec,CplxSxpRec,RawSxpRec,CharSxpRec)
typealias VectorAtomicSxp{S<:VectorAtomicSxpRec} Ptr{S}

typealias VectorNumericSxpRec Union(LglSxpRec,IntSxpRec,RealSxpRec,CplxSxpRec)
typealias VectorNumericSxp{S<:VectorNumericSxpRec} Ptr{S}

typealias VectorListSxpRec Union(VecSxpRec,StrSxpRec,ExprSxpRec)
typealias VectorListSxp{S<:VectorListSxpRec} Ptr{S}

typealias PairListSxpRec Union(NilSxpRec,ListSxpRec,LangSxpRec)
typealias PairListSxp{S<:PairListSxpRec} Ptr{S}

typealias PrimitiveSxpRec Union(BuiltinSxpRec,SpecialSxpRec)
typealias PrimitiveSxp{S<:PrimitiveSxpRec} Ptr{S}

typealias FunctionSxpRec Union(ClosSxpRec,BuiltinSxpRec,SpecialSxpRec)
typealias FunctionSxp{S<:FunctionSxpRec} Ptr{S}

@doc """
Element types of R vectors.
"""->
eltype(::Type{LglSxpRec}) = Cint
eltype(::Type{IntSxpRec}) = Cint
eltype(::Type{RealSxpRec}) = Float64
eltype(::Type{CplxSxpRec}) = Complex128
eltype(::Type{CharSxpRec}) = UInt8
eltype(::Type{RawSxpRec}) = UInt8

eltype(::Type{StrSxpRec}) = Ptr{CharSxpRec}
eltype(::Type{VecSxpRec}) = Ptr{SxpRecHead}
eltype(::Type{ExprSxpRec}) = Ptr{SxpRecHead}





@doc """
The general user-facing type for R objects. It is protected from garbage collection until being finalized by Julia
"""->
type RObject{S<:SxpRec}
    p::Ptr{S}
    function RObject(p::Ptr{S})
        preserve(p)
        r = new(p)
        finalizer(r, release)
        r
    end
end
RObject{S<:SxpRec}(p::Ptr{S}) = RObject{S}(p)
RObject(x::RObject) = x
RObject(x) = RObject(sexp(x))


# convert{T}(::Type{T}, r::RObject) = convert(T,r.p)

@doc """
Prevent garbage collection of an R object. Object can be released via `release`.

This is slower than `protect`, as it requires searching an internal list, but
more flexible.
"""->
preserve{S<:SxpRec}(p::Ptr{S}) = ccall((:R_PreserveObject,libR), Void, (Ptr{S},), p)

@doc """
Release object that has been gc protected by `preserve`.
"""->
release{S<:SxpRec}(p::Ptr{S}) = ccall((:R_ReleaseObject,libR),Void,(Ptr{S},),p)
release{S<:SxpRec}(r::RObject{S}) = release(r.p)

@doc """ 

Stack-based protection of garbage collection of R objects. Objects are
released via `unprotect`. Returns the same pointer, allowing inline use.

This is faster than `preserve`, but more restrictive. Really only useful
inside functions.
"""->
protect{S<:SxpRec}(p::Ptr{S}) = ccall((:Rf_protect,libR), Ptr{S}, (Ptr{S},), p)

@doc """
Release last `n` objects gc-protected by `protect`.
"""->
unprotect(n::Integer) = ccall((:Rf_unprotect,libR), Void, (Cint,), n)

@doc """
The SEXPTYPE number of a `SxpRec`

Determined from the trailing 5 bits of the first 32-bit word, is
a 0-based index into the `info` field of a `SxpRecHead`.
"""->
sexpnum(h::SxpRecHead) = h.info & 0x1f
sexpnum(p::Sxp) = sexpnum(unsafe_load(p))

@doc "vector of R SxpRec types"->
const typs = [NilSxpRec,SymSxpRec,ListSxpRec,ClosSxpRec,EnvSxpRec,
              PromSxpRec,LangSxpRec,SpecialSxpRec,BuiltinSxpRec,CharSxpRec,
              LglSxpRec,Void,Void,IntSxpRec,RealSxpRec,
              CplxSxpRec,StrSxpRec,DotSxpRec,AnySxpRec,VecSxpRec,
              ExprSxpRec,BcodeSxpRec,ExtPtrSxpRec,WeakRefSxpRec,RawSxpRec,
              S4SxpRec]

for (i,T) in enumerate(typs)
    if T != Void
        @eval sexpnum(::Type{$T}) = $(i-1)
    end
end


@doc """
Convert a `Ptr{SxpRecHead}` to an approptiate `Sxp`.
"""->
function sexp(p::Ptr{SxpRecHead})
    typ = sexpnum(p)
    0 ≤ typ ≤ 10 || 13 ≤ typ ≤ 25 || error("Unknown SEXPTYPE $typ")
    styp = typs[typ+1]
    convert(Ptr{styp},p)
end
sexp(s::Sxp) = s
sexp(r::RObject) = r.p

