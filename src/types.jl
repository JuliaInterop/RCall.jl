"""
    Sxp

Representation of R symbolic expression record `SEXPREC` in R API.

These are represented by a pointer `Ptr{S<:Sxp}` (which is called `SEXP` in R API).

See also [R internals documentation](https://cran.r-project.org/doc/manuals/r-devel/R-ints.html)
"""
abstract type Sxp end # SEXPREC

"""
    SxpPtrInfo

Representation of `sxpinfo_struct`.
"""
const SxpPtrInfo = UInt32 # sxpinfo_struct

"""
    SxpHead <: Sxp

R Sxp header (`SEXPREC_HEADER`).

A pointer to this is used for unknown types.

# Fields
- `info::SxpPtrInfo`
- `attrib::Ptr{Cvoid}`
- `gc_next::Ptr{Cvoid}`
- `gc_prev::Ptr{Cvoid}`
"""
struct SxpHead <: Sxp
    info::SxpPtrInfo
    attrib::Ptr{Cvoid}
    gc_next::Ptr{Cvoid}
    gc_prev::Ptr{Cvoid}
end

"""$(@doc SxpHead)"""
const UnknownSxp = SxpHead

abstract type VectorSxp <: Sxp end
abstract type VectorAtomicSxp <: VectorSxp end
abstract type VectorNumericSxp <: VectorAtomicSxp end
abstract type VectorListSxp <: VectorSxp end
abstract type PairListSxp <: Sxp end
abstract type FunctionSxp <: Sxp end

"""
    NilSxpR <: PairListSxp

Representation of R `NULL` value.

This corresponds to R type tag 0.

# Fields
- `head::SxpHead`
"""
struct NilSxp <: PairListSxp
    head::SxpHead
end

"""
    ListSxp <: PairListSxp

Representation of R pairs (cons) list cell.

This corresponds to R type tag 2.

# Fields
- `head::SxpHead`
- `car::Ptr{UnknownSxp}`
- `cdr::Ptr{UnknownSxp}`
- `tag::Ptr{UnknownSxp}`
"""
struct ListSxp <: PairListSxp
    head::SxpHead
    car::Ptr{UnknownSxp}
    cdr::Ptr{UnknownSxp}
    tag::Ptr{UnknownSxp}
end

"""
    ClosSxp <: FunctionSxp

Representation of R function closure.

This corresponds to R type tag 3.

# Fields
- `head::SxpHead`
- `formals::Ptr{ListSxp}`
- `body::Ptr{UnknownSxp}`
- `env::Ptr{UnknownSxp}`
"""
struct ClosSxp <: FunctionSxp
    head::SxpHead
    formals::Ptr{ListSxp}
    body::Ptr{UnknownSxp}
    env::Ptr{UnknownSxp}
end

"""
    EnvSxp <: Sxp

Representation of R environment.

This corresponds to type tag 4.

# Fields
- `head::SxpHead`
- `frame::Ptr{UnknownSxp}`
- `enclos::Ptr{UnknownSxp}`
- `hashtab::Ptr{UnknownSxp}`
"""
struct EnvSxp <: Sxp
    head::SxpHead
    frame::Ptr{UnknownSxp}
    enclos::Ptr{UnknownSxp}
    hashtab::Ptr{UnknownSxp}
end

"""
    PromSxp <: Sxp

Representation of R promise.

This corresponds to type tag 5.

# Fields
- `head::SxpHead`
- `value::Ptr{UnknownSxp}`
- `expr::Ptr{UnknownSxp}`
- `env::Ptr{UnknownSxp}`
"""
struct PromSxp <: Sxp
    head::SxpHead
    value::Ptr{UnknownSxp}
    expr::Ptr{UnknownSxp}
    env::Ptr{UnknownSxp}
end

"""
    LangSxp <: PairListSxp

Representation of R function call.

This corresponds to type tag 6.

# Fields
- `head::SxpHead`
- `car::Ptr{UnknownSxp}`
- `cdr::Ptr{UnknownSxp}`
- `tag::Ptr{UnknownSxp}`
"""
struct LangSxp <: PairListSxp
    head::SxpHead
    car::Ptr{UnknownSxp}
    cdr::Ptr{UnknownSxp}
    tag::Ptr{UnknownSxp}
end

"""
    SpecialSxp <: FunctionSxp

Representation of R special function.

This corresponds to type tag 7.

# Fields
- `head::SxpHead`
"""
struct SpecialSxp <: FunctionSxp
    head::SxpHead
end

"""
    BuiltinSxp <: FunctionSxp

Representation of R built-in function.

This corresponds to type tag 8.

# Fields
- `head::SxpHead`
"""
struct BuiltinSxp <: FunctionSxp
    head::SxpHead
end

"""
    CharSxp <: VectorAtomicSxp

Representation of R character string.

This corresponds to type tag 9.

# Fields
- `head::SxpHead`
- `length::Cint`
- `truelength::Cint`
"""
struct CharSxp <: VectorAtomicSxp
    head::SxpHead
    length::Cint
    truelength::Cint
end

"""
    SymSxp <: Sxp

Representation of R symbol.

This corresponds to type tag 1.

# Fields
- `head::SxpHead`
- `name::Ptr{CharSxp}`
- `value::Ptr{UnknownSxp}`
- `internal::Ptr{UnknownSxp}`
"""
struct SymSxp <: Sxp
    head::SxpHead
    name::Ptr{CharSxp}
    value::Ptr{UnknownSxp}
    internal::Ptr{UnknownSxp}
end

"""
    LglSxp <: VectorNumericSxp

Representation of R logical vector.

This corresponds to type tag 10.

# Fields
- `head::SxpHead`
- `length::Cint`
- `truelength::Cint`
"""
struct LglSxp <: VectorNumericSxp
    head::SxpHead
    length::Cint
    truelength::Cint
end

""""
    IntSxp <: VectorNumericSxp

Representation of R integer vector.

This corresponds to type tag 13.

# Fields
- `head::SxpHead`
- `length::Cint`
- `truelength::Cint`
"""
struct IntSxp <: VectorNumericSxp
    head::SxpHead
    length::Cint
    truelength::Cint
end

"""
    RealSxp <: VectorNumericSxp

Representation of R real (numeric) vector.

This correponds to type tag 14.

# Fields
- `head::SxpHead`
- `length::Cint`
- `truelength::Cint`
"""
struct RealSxp <: VectorNumericSxp
    head::SxpHead
    length::Cint
    truelength::Cint
end

"""
    CplxSxp <: VectorNumericSxp

Representation of R complex vector.

This corresponds to type tag 15.

# Fields
- `head::SxpHead`
- `length::Cint`
- `truelength::Cint`
"""
struct CplxSxp <: VectorNumericSxp
    head::SxpHead
    length::Cint
    truelength::Cint
end

"""
    StrSxp <: VectorListSxp

Representation of R vector of character strings.

This correponds to type tag 16.

# Fields
- `head::SxpHead`
- `length::Cint`
- `truelength::Cint`
"""
struct StrSxp <: VectorListSxp
    head::SxpHead
    length::Cint
    truelength::Cint
end

"""
    DotSxp <: Sxp

Representation of R dot-dot-dot object.

This corresponds to type tag 17.

# Fields
- `head::SxpHead`
"""
struct DotSxp <: Sxp
    head::SxpHead
end

"""
    AnySxp <: Sxp

Representation of R "any" object (comparable to `Ref{Any}`).

This corresponds to type tag 18.

# Fields
- `head::SxpHead`
"""
struct AnySxp <: Sxp
    head::SxpHead
end

"""
    VecSxp <: VectorListSxp

Representation of R list (i.e. `Array{Any,1}`).

This corresponds to type tag 19.

# Fields
- `head::SxpHead`
- `length::Cint`
- `truelength::Cint`
"""
struct VecSxp <: VectorListSxp
    head::SxpHead
    length::Cint
    truelength::Cint
end



"""
    ExprSxp <: VectorListSxp

Representation of R expression vector.

This corresponds to type tag 20.

# Fields
- `head::SxpHead`
- `length::Cint`
- `truelength::Cint`
"""
struct ExprSxp <: VectorListSxp
    head::SxpHead
    length::Cint
    truelength::Cint
end

""""
    BcodeSxp <: Sxp

Representation of R byte code.

This corresponds to type tag 21.

# Fields
- `head::SxpHead`
"""
struct BcodeSxp <: Sxp
    head::SxpHead
end

"""
    ExtPtrSxp <: Sxp

Representation of R external pointer.

This corresponds to type tag 22.

# Fields
- `head::SxpHead`
- `ptr::Ptr{Cvoid}`
- `prot::Ptr{Cvoid}`
- `tag::Ptr{UnknownSxp}`
"""
struct ExtPtrSxp <: Sxp
    head::SxpHead
    ptr::Ptr{Cvoid}
    prot::Ptr{Cvoid}
    tag::Ptr{UnknownSxp}
end

"""
    WeakRefSxp <: Sxp

Representation of R weak reference.

This corresponds to type tag 23.

# Fields
- `head::SxpHead`
- `length::Cint`
- `truelength::Cint`
"""
struct WeakRefSxp <: Sxp
    head::SxpHead
end

"""
    RawSxp <: VectorAtomicSxp

Representation of R byte vector.

This corresponds to type tag 24.

# Fields
- `head::SxpHead`
- `length::Cint`
- `truelength::Cint`
"""
struct RawSxp <: VectorAtomicSxp
    head::SxpHead
    length::Cint
    truelength::Cint
end

"""
    S4Sxp <: Sxp

Representation of R S4 object.

This corresponds to type tag 24.

# Fields
- `head::SxpHead`
"""
struct S4Sxp <: Sxp
    head::SxpHead
end

"""
    RObject{S<:Sxp}

An `RObject` is a Julia wrapper for an R object (known as an "S-expression", i.e. `SEXP`).
It is stored as a pointer which is protected from the R garbage collector,
until the `RObject` itself is finalized by Julia. The parameter is the type of the S-expression.

When called with a Julia object as an argument, a corresponding R object is constructed.

# Examples

```jldoctest
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

# Fields
- `p::Ptr{S}` Pointer to the relevant R object.
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
    RObject{SymSxp}(p::Ptr{SymSxp}) = new{SymSxp}(p)
end

RObject(p::Ptr{S}) where S<:Sxp = RObject{S}(p)
RObject(x::RObject) = x

"""
    RClass{Symbol}

Representation of R Class.

Examples:
- `RCall{:logical}`
- `RCall{:integer}`
- `RCall{:numeric}`
- `RCall{:character}`
"""
struct RClass{Symbol} end

# Element types of R vectors.
eltype(::Type{LglSxp}) = Cint
eltype(::Type{IntSxp}) = Cint
eltype(::Type{RealSxp}) = Float64
eltype(::Type{CplxSxp}) = ComplexF64
eltype(::Type{CharSxp}) = UInt8
eltype(::Type{RawSxp}) = UInt8

eltype(::Type{StrSxp}) = Ptr{CharSxp}
eltype(::Type{VecSxp}) = Ptr{UnknownSxp}
eltype(::Type{ExprSxp}) = Ptr{UnknownSxp}

eltype(::Ptr{S}) where S<:Sxp = eltype(S)
eltype(::RObject{S}) where S<:Sxp = eltype(S)

"""
    preserve(p::Ptr{<:Sxp})

Prevent garbage collection of an R object.

Object can be released via [`release`](@ref).

This is slower than [`protect`](@ref), as it requires searching an internal list,
but more flexible.
"""
preserve(p::Ptr{S}) where S<:Sxp = ccall((:R_PreserveObject, libR), Nothing, (Ptr{S},), p)

"""
    release(p::Ptr{<:Sxp})
    release(p::RObject{<:Sxp})

Release object that has been GC protected by [`preserve`](@ref).
"""
release(p::Ptr{S}) where S<:Sxp = ccall((:R_ReleaseObject,libR), Nothing, (Ptr{S},), p)
release(r::RObject{S}) where S<:Sxp = release(r.p)

"""
    protect(p::Ptr{<:Sxp})

Stack-based protection of garbage collection of R objects.

Objects are released via [`unprotect`](@ref).
Returns the same pointer, allowing inline use.

This is faster than [`preserve`](@ref), but more restrictive.
Really only useful inside functions, where you can control the `unprotect` step.
"""
protect(p::Ptr{S}) where S<:Sxp = ccall((:Rf_protect,libR), Ptr{S}, (Ptr{S},), p)

"""
    unprotect(n)

Release last `n` objects GC-protected by [`protect`](@ref).
"""
unprotect(n::Integer) = ccall((:Rf_unprotect,libR), Nothing, (Cint,), n)

"""
    sexpnum(s::Sxp)
    sexpnum(p::Ptr{<:Sxp})

Return the `SEXPTYPE` number, i.e. type tag, of a `Sxp`.

Determined from the trailing 5 bits of the first 32-bit word. Is
a 0-based index into the `info` field of a [`SxpHead`](@ref).
"""
sexpnum(h::SxpHead) = h.info & 0x1f
sexpnum(p::Ptr{S}) where S<:Sxp = sexpnum(unsafe_load(p))

"""
    SXP_TYPES

Ordered collection of R `SEXP` types, so that the (index - 1)
matches the type tag.
"""
const SXP_TYPES = (NilSxp, SymSxp, ListSxp, ClosSxp, EnvSxp,
                   PromSxp, LangSxp, SpecialSxp, BuiltinSxp, CharSxp,
                   LglSxp, Nothing, Nothing, IntSxp, RealSxp,
                   CplxSxp, StrSxp, DotSxp, AnySxp, VecSxp,
                   ExprSxp, BcodeSxp, ExtPtrSxp, WeakRefSxp, RawSxp,
                   S4Sxp)

for (i, T) in enumerate(SXP_TYPES)
    if T != Nothing
        @eval sexpnum(::Type{$T}) = $(i-1)
    end
end


"""
    sexp(p::Ptr{UnknownSxp})

Return a restrictively parameterized `Ptr{<:Sxp}` pointing to the same object as `p`.
"""
function sexp(p::Ptr{UnknownSxp})
    typ = sexpnum(p)
    0 ≤ typ ≤ 10 || 13 ≤ typ ≤ 25 || error("Unknown SEXPTYPE $typ")
    styp = SXP_TYPES[typ+1]
    return Ptr{styp}(p)
end
sexp(s::Ptr{S}) where S<:Sxp = s
sexp(r::RObject) = r.p

"""
   sexp(::Type{<:Sxp}, s::RObject{<:Sxp})

Return the associated `Sxp` pointer.
"""
sexp(::Type{S}, r::RObject{S}) where S<:Sxp = r.p
# do we need this method?
sexp(::Type{S}, s::Ptr{S}) where S<:Sxp = s
