"""
RCall.jl's type `Sxp` mirrors the R symbolic expression record `SEXPREC` in R API.
These are represented by a pointer `Ptr{S<:Sxp}` (which is called `SEXP` in R API).
"""
abstract type Sxp end # SEXPREC
const SxpPtrInfo = UInt32 # sxpinfo_struct

"R Sxp header: a pointer to this is used for unknown types."
struct SxpHead <: Sxp # SEXPREC_HEADER
    info::SxpPtrInfo
    attrib::Ptr{Cvoid}
    gc_next::Ptr{Cvoid}
    gc_prev::Ptr{Cvoid}
end
const UnknownSxp = SxpHead

abstract type VectorSxp <: Sxp end
abstract type VectorAtomicSxp <: VectorSxp end
abstract type VectorNumericSxp <: VectorAtomicSxp end
abstract type VectorListSxp <: VectorSxp end
abstract type PairListSxp <: Sxp end
abstract type FunctionSxp <: Sxp end


"R NULL value"
struct NilSxp <: PairListSxp   # type tag 0
    head::SxpHead
end

"R pairs (cons) list cell"
struct ListSxp <: PairListSxp  # type tag 2
    head::SxpHead
    car::Ptr{UnknownSxp}
    cdr::Ptr{UnknownSxp}
    tag::Ptr{UnknownSxp}
end

"R function closure"
struct ClosSxp <: FunctionSxp  # type tag 3
    head::SxpHead
    formals::Ptr{ListSxp}
    body::Ptr{UnknownSxp}
    env::Ptr{UnknownSxp}
end

"R environment"
struct EnvSxp <: Sxp  # type tag 4
    head::SxpHead
    frame::Ptr{UnknownSxp}
    enclos::Ptr{UnknownSxp}
    hashtab::Ptr{UnknownSxp}
end

"R promise"
struct PromSxp <: Sxp  # type tag 5
    head::SxpHead
    value::Ptr{UnknownSxp}
    expr::Ptr{UnknownSxp}
    env::Ptr{UnknownSxp}
end

"R function call"
struct LangSxp <: PairListSxp  # type tag 6
    head::SxpHead
    car::Ptr{UnknownSxp}
    cdr::Ptr{UnknownSxp}
    tag::Ptr{UnknownSxp}
end

"R special function"
struct SpecialSxp <: FunctionSxp  # type tag 7
    head::SxpHead
end

"R built-in function"
struct BuiltinSxp <: FunctionSxp  # type tag 8
    head::SxpHead
end

"R character string"
struct CharSxp <: VectorAtomicSxp     # type tag 9
    head::SxpHead
    length::Cint
    truelength::Cint
end

"R symbol"
struct SymSxp <: Sxp   # type tag 1
    head::SxpHead
    name::Ptr{CharSxp}
    value::Ptr{UnknownSxp}
    internal::Ptr{UnknownSxp}
end

"R logical vector"
struct LglSxp <: VectorNumericSxp     # type tag 10
    head::SxpHead
    length::Cint
    truelength::Cint
end

"R integer vector"
struct IntSxp <: VectorNumericSxp     # type tag 13
    head::SxpHead
    length::Cint
    truelength::Cint
end

"R real vector"
struct RealSxp <: VectorNumericSxp    # type tag 14
    head::SxpHead
    length::Cint
    truelength::Cint
end

"R complex vector"
struct CplxSxp <: VectorNumericSxp    # type tag 15
    head::SxpHead
    length::Cint
    truelength::Cint
end

"R vector of character strings"
struct StrSxp <: VectorListSxp     # type tag 16
    head::SxpHead
    length::Cint
    truelength::Cint
end

"R dot-dot-dot object"
struct DotSxp <: Sxp     # type tag 17
    head::SxpHead
end

"R \"any\" object"
struct AnySxp <: Sxp     # type tag 18
    head::SxpHead
end

"R list (i.e. Array{Any,1})"
struct VecSxp <: VectorListSxp     # type tag 19
    head::SxpHead
    length::Cint
    truelength::Cint
end

"R expression vector"
struct ExprSxp <: VectorListSxp    # type tag 20
    head::SxpHead
    length::Cint
    truelength::Cint
end

"R byte code"
struct BcodeSxp <: Sxp   # type tag 21
    head::SxpHead
end

"R external pointer"
struct ExtPtrSxp <: Sxp  # type tag 22
    head::SxpHead
    ptr::Ptr{Cvoid}
    prot::Ptr{Cvoid}
    tag::Ptr{UnknownSxp}
end

"R weak reference"
struct WeakRefSxp <: Sxp  # type tag 23
    head::SxpHead
end

"R byte vector"
struct RawSxp <: VectorAtomicSxp      # type tag 24
    head::SxpHead
    length::Cint
    truelength::Cint
end

"R S4 object"
struct S4Sxp <: Sxp      # type tag 25
    head::SxpHead
end

"""
An `RObject` is a Julia wrapper for an R object (known as an "S-expression" or "SEXP"). It is stored as a pointer which is protected from the R garbage collector, until the `RObject` itself is finalized by Julia. The parameter is the type of the S-expression.

When called with a Julia object as an argument, a corresponding R object is constructed.

```julia_skip
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
"""
mutable struct RObject{S<:Sxp}
    p::Ptr{S}
    # used for pre-defined constants
    function RObject{S}() where S
        new{S}(C_NULL)
    end
    function RObject{S}(p::Ptr{S}) where S
        preserve(p)
        r = new{S}(p)
        finalizer(release, r)
        r
    end
    # SymSxps are not garbage collected, so preserve not necessary.
    RObject{S}(p::Ptr{SymSxp}) where S = new{S}(p)
end


RObject(p::Ptr{S}) where S<:Sxp = RObject{S}(p)
RObject(x::RObject) = x


"""
R Class
"""
struct RClass{Symbol} end


"""
Element types of R vectors.
"""
eltype(::Type{LglSxp}) = Cint
eltype(::Type{IntSxp}) = Cint
eltype(::Type{RealSxp}) = Float64
eltype(::Type{CplxSxp}) = ComplexF64
eltype(::Type{CharSxp}) = UInt8
eltype(::Type{RawSxp}) = UInt8

eltype(::Type{StrSxp}) = Ptr{CharSxp}
eltype(::Type{VecSxp}) = Ptr{UnknownSxp}
eltype(::Type{ExprSxp}) = Ptr{UnknownSxp}

eltype(s::Ptr{S}) where S<:Sxp = eltype(S)
eltype(s::RObject{S}) where S<:Sxp = eltype(S)


"""
Prevent garbage collection of an R object. Object can be released via `release`.

This is slower than `protect`, as it requires searching an internal list, but
more flexible.
"""
preserve(p::Ptr{S}) where S<:Sxp = ccall((:R_PreserveObject,libR), Nothing, (Ptr{S},), p)

"""
Release object that has been gc protected by `preserve`.
"""
release(p::Ptr{S}) where S<:Sxp = ccall((:R_ReleaseObject,libR),Nothing,(Ptr{S},),p)
release(r::RObject{S}) where S<:Sxp = release(r.p)

"""
Stack-based protection of garbage collection of R objects. Objects are
released via `unprotect`. Returns the same pointer, allowing inline use.

This is faster than `preserve`, but more restrictive. Really only useful
inside functions.
"""
protect(p::Ptr{S}) where S<:Sxp = ccall((:Rf_protect,libR), Ptr{S}, (Ptr{S},), p)

"""
Release last `n` objects gc-protected by `protect`.
"""
unprotect(n::Integer) = ccall((:Rf_unprotect,libR), Nothing, (Cint,), n)

"""
The SEXPTYPE number of a `Sxp`

Determined from the trailing 5 bits of the first 32-bit word. Is
a 0-based index into the `info` field of a `SxpHead`.
"""
sexpnum(h::SxpHead) = h.info & 0x1f
sexpnum(p::Ptr{S}) where S<:Sxp = sexpnum(unsafe_load(p))

"vector of R Sxp types"
const typs = [NilSxp,SymSxp,ListSxp,ClosSxp,EnvSxp,
              PromSxp,LangSxp,SpecialSxp,BuiltinSxp,CharSxp,
              LglSxp,Nothing,Nothing,IntSxp,RealSxp,
              CplxSxp,StrSxp,DotSxp,AnySxp,VecSxp,
              ExprSxp,BcodeSxp,ExtPtrSxp,WeakRefSxp,RawSxp,
              S4Sxp]

for (i,T) in enumerate(typs)
    if T != Nothing
        @eval sexpnum(::Type{$T}) = $(i-1)
    end
end


"""
Convert a `Ptr{UnknownSxp}` to an appropriate `Ptr{S<:Sxp}`.
"""
function sexp(p::Ptr{UnknownSxp})
    typ = sexpnum(p)
    0 ≤ typ ≤ 10 || 13 ≤ typ ≤ 25 || error("Unknown SEXPTYPE $typ")
    styp = typs[typ+1]
    Ptr{styp}(p)
end
sexp(s::Ptr{S}) where S<:Sxp = s
sexp(r::RObject) = r.p

sexp(::Type{S},s::Ptr{S}) where S<:Sxp = s
sexp(::Type{S},r::RObject{S}) where S<:Sxp = r.p
