@doc "R NULL value"->
type NilSxp <: SEXPREC   # type tag 0
    info::Cint
    p::Ptr{Void}
end

@doc "R symbol"->
type SymSxp <: SEXPREC   # type tag 1
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
    genc_prev::Ptr{Void}
    pname::Ptr{Void}
    value::Ptr{Void}
    internal::Ptr{Void}
end

@doc "R pairs (cons) list cell"->
type ListSxp <: SEXPREC  # type tag 2
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
    genc_prev::Ptr{Void}
    car::Ptr{Void}
    cdr::Ptr{Void}
    tag::Ptr{Void}
end

@doc "R function closure"->
type ClosSxp <: SEXPREC  # type tag 3
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
    genc_prev::Ptr{Void}
    formals::Ptr{Void}
    body::Ptr{Void}
    env::Ptr{Void}
end

@doc "R environment"->
type EnvSxp <: SEXPREC  # type tag 4
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
    genc_prev::Ptr{Void}
    frame::Ptr{Void}
    enclos::Ptr{Void}
    hashtab::Ptr{Void}
end

@doc "R promise"->
type PromSxp <: SEXPREC  # type tag 5
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
    genc_prev::Ptr{Void}
    value::Ptr{Void}
    expr::Ptr{Void}
    env::Ptr{Void}
end

@doc "R function call"->
type LangSxp <: SEXPREC  # type tag 6
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
    genc_prev::Ptr{Void}
    value::Ptr{Void}
    expr::Ptr{Void}
    env::Ptr{Void}
end

@doc "R special function"->
type SpecialSxp <: SEXPREC  # type tag 7
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
    genc_prev::Ptr{Void}
    car::Ptr{Void}
    cdr::Ptr{Void}
    tag::Ptr{Void}
end

@doc "R built-in function"->
type BuiltinSxp <: SEXPREC  # type tag 8
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
    genc_prev::Ptr{Void}
    car::Ptr{Void}
    cdr::Ptr{Void}
    tag::Ptr{Void}
end

@doc "R character string"->
type CharSxp <: SEXPREC     # type tag 9
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
    pv::Ptr{Uint8}
    length::Cint
    truelength::Cint
end

@doc "R logical vector"->
type LglSxp <: SEXPREC     # type tag 10
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
    pv::Ptr{Int32}
    length::Cint
    truelength::Cint
end

@doc "R integer vector"->
type IntSxp <: SEXPREC     # type tag 13
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
    pv::Ptr{Int32}
    length::Cint
    truelength::Cint
end

@doc "R real vector"->
type RealSxp <: SEXPREC    # type tag 14
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
    pv::Ptr{Float64}
    length::Cint
    truelength::Cint
end

@doc "R complex vector"->
type CplxSxp <: SEXPREC    # type tag 15
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
    pv::Ptr{Complex128}
    length::Cint
    truelength::Cint
end

@doc "R vector of character strings"->
type StrSxp <: SEXPREC     # type tag 16
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
    pv::Ptr{Ptr{Void}}
    length::Cint
    truelength::Cint
end

@doc "R dot-dot-dot object"->
type DotSxp <: SEXPREC     # type tag 17
    info::Cint
    p::Ptr{Void}
end

@doc "R \"any\" object"->
type AnySxp <: SEXPREC     # type tag 18
    info::Cint
    p::Ptr{Void}
end

@doc "R list (i.e. Array{Any,1})"->
type VecSxp <: SEXPREC     # type tag 19
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
    pv::Ptr{Ptr{Void}}
    length::Cint
    truelength::Cint
end

@doc "R expression vector"->
type ExprSxp <: SEXPREC    # type tag 20
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
    pv::Ptr{Ptr{Void}}
    length::Cint
    truelength::Cint
end

@doc "R byte code"->
type BcodeSxp <: SEXPREC   # type tag 21
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
    genc_prev::Ptr{Void}
    code::Ptr{Void}
    consts::Ptr{Void}
    expr::Ptr{Void}
end

@doc "R external pointer"->
type ExtPtrSxp <: SEXPREC  # type tag 22
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
    genc_prev::Ptr{Void}
    ptr::Ptr{Void}
    prot::Ptr{Void}
    tag::Ptr{Void}
end

@doc "R weak reference"->
type WeakRefSxp <: SEXPREC  # type tag 23
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
    genc_prev::Ptr{Void}
end

@doc "R byte vector"->
type RawSxp <: SEXPREC      # type tag 24
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
    pv::Ptr{Uint8}
    length::Cint
    truelength::Cint
end

@doc "R S4 object"->
type S4Sxp <: SEXPREC      # type tag 25
    info::Cint
    attrib::Ptr{Void}
    p::Ptr{Void}
end

@doc "Vector types in R"->
typealias RVector Union(CharSxp,LglSxp,IntSxp,RealSxp,CplxSxp,StrSxp,VecSxp,ExprSxp,RawSxp)

typealias VectorAtomic Union(LglSxp,IntSxp,RealSxp,CplxSxp,RawSxp,CharSxp)

typealias VectorList Union(VecSxp,StrSxp,ExprSxp)

typealias PairList Union(NilSxp,ListSxp,LangSxp)

typealias Primitive Union(BuiltinSxp,SpecialSxp)

typealias RFunction Union(ClosSxp,BuiltinSxp,SpecialSxp)

if VERSION < v"v0.4-"
    @doc """
    Extract the original SEXP (pointer to an R SEXPREC)

    Written as a `convert` method for convenience in `ccall`
    """->
    Base.convert(::Type{Ptr{Void}},s::SEXPREC) = s.p
else
    @doc """
    Extract the original SEXP (pointer to an R SEXPREC)

    Written as a `unsafe_convert` method for convenience in `ccall`
    """->
    Base.unsafe_convert(::Type{Ptr{Void}},s::SEXPREC) = s.p
end

@doc """
SEXPREC methods for `length` return the R length.

`Rf_length` handles SEXPRECs that are not vector-like and R's
"long vectors", which have a negative value for the `length` member.
"""->
Base.length(s::SEXPREC) = ccall((:Rf_length,libR),Int,(Ptr{Void},),s)
function Base.length(s::RVector)
    l = @compat(Int(s.length))
    l < 0 ? ccall((:Rf_length,libR),Int,(Ptr{Void},),s) : l
end
