# logic for default rcopy

"""
`rcopy(r)` copies the contents of an R object into a corresponding canonical Julia type.
"""
rcopy(r::RObject{S}; kwargs...) where S<:Sxp = rcopy(r.p; kwargs...)

function rcopy(s::Ptr{S}; kwargs...) where S<:Sxp
    protect(s)
    try
        class = rcopy(Symbol, getclass(s, true))
        return rcopy(rcopytype(RClass{class}, s), s; kwargs...)
    finally
        unprotect(1)
    end
end

# Default behaviors of copying R vectors to AbstractArray

function rcopy(::Type{AbstractArray}, s::Ptr{S}) where S<:Sxp
    protect(s)
    try
        if isFactor(s)
            return rcopy(CategoricalArray, s)
        else
            return anyna(s) ? rcopy(DataArray, s) : rcopy(Array, s)
        end
    finally
        unprotect(1)
    end
end

# Default behaviors of copying R vectors to arrays

for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp, :RawSxp)
    @eval begin
        function rcopy(::Type{Vector},s::Ptr{$S})
            protect(s)
            try
                class = rcopy(Symbol, getclass(s, true))
                return rcopy(Vector{eltype(RClass{class}, s)}, s)
            finally
                unprotect(1)
            end
        end
        function rcopy(::Type{Array},s::Ptr{$S})
            protect(s)
            try
                class = rcopy(Symbol, getclass(s, true))
                return rcopy(Array{eltype(RClass{class}, s)}, s)
            finally
                unprotect(1)
            end
        end
    end
end

# NilSxp
rcopy(::Ptr{NilSxp}) = Nullable()

# SymSxp and CharSxp
rcopy(s::Ptr{SymSxp}) = rcopy(Symbol,s)
rcopy(s::Ptr{CharSxp}) = rcopy(String,s)

# StrSxp
function rcopytype(::Type{RClass{Sym}}, s::Ptr{StrSxp}) where Sym
    if length(s) == 1
        String
    elseif anyna(s)
        DataArray{String}
    else
        Array{String}
    end
end
eltype(::Type{RClass{Sym}}, s::Ptr{StrSxp}) where Sym = String

function rcopytype(::Type{RClass{Sym}}, s::Ptr{IntSxp}) where Sym
    if length(s) == 1
        Int
    elseif isFactor(s)
        CategoricalArray
    elseif anyna(s)
        DataArray{Int}
    else
        Array{Int}
    end
end

eltype(::Type{RClass{Sym}}, s::Ptr{IntSxp}) where Sym = Int

function rcopytype(::Type{RClass{Sym}}, s::Ptr{RealSxp}) where Sym
    if length(s) == 1
        Float64
    elseif anyna(s)
        DataArray{Float64}
    else
        Array{Float64}
    end
end
eltype(::Type{RClass{Sym}}, s::Ptr{RealSxp}) where Sym = Float64


function rcopytype(::Type{RClass{Sym}}, s::Ptr{CplxSxp}) where Sym
    if length(s) == 1
        Complex128
    elseif anyna(s)
        DataArray{Complex128}
    else
        Array{Complex128}
    end
end
eltype(::Type{RClass{Sym}}, s::Ptr{CplxSxp}) where Sym = Complex128


function rcopytype(::Type{RClass{Sym}}, s::Ptr{LglSxp}) where Sym
    if length(s) == 1
        Bool
    elseif anyna(s)
        DataArray{Bool}
    else
        BitArray
    end
end
eltype(::Type{RClass{Sym}}, s::Ptr{LglSxp}) where Sym = Bool


function rcopytype(::Type{RClass{Sym}}, s::Ptr{RawSxp}) where Sym
    if length(s) == 1
        UInt8
    elseif anyna(s)
        DataArray{UInt8}
    else
        Array{UInt8}
    end
end
eltype(::Type{RClass{Sym}}, s::Ptr{RawSxp}) where Sym = UInt8


# VecSxp
function rcopytype(::Type{RClass{Sym}}, s::Ptr{VecSxp}) where Sym
    if isFrame(s)
        DataFrame
    elseif isnull(getnames(s))
        Array{Any}
    else
        OrderedDict{Symbol,Any}
    end
end

# FunctionSxp
rcopy(s::Ptr{S}) where S<:FunctionSxp = rcopy(Function,s)

# TODO: LangSxp
rcopy(l::Ptr{LangSxp}) = RObject(l)
rcopy(r::RObject{LangSxp}) = r

# Fallback for non SEXP
rcopy(r) = r

# logic of default sexp

"""
`sexp(x)` converts a Julia object `x` to a pointer to a corresponding Sxp Object.
"""

RObject(s) = RObject(sexp(s))

# nothing
sexp(::Void) = sexp(Const.NilValue)

# Nullable
sexp(::Nullable{Union{}}) = sexp(Const.NilValue)

# Missing
sexp(::Missing) = sexp(LglSxp, Const.NaInt)

# Symbol
sexp(s::Symbol) = sexp(SymSxp,s)

# DataFrame
sexp(d::AbstractDataFrame) = sexp(VecSxp, d)


# Number, Array and DataArray
for (J,S) in ((:Integer,:IntSxp),
                 (:AbstractFloat, :RealSxp),
                 (:Complex, :CplxSxp),
                 (:Bool, :LglSxp),
                 (:AbstractString, :StrSxp))
    @eval begin
        sexp(a::AbstractArray{T}) where T<:$J = sexp($S,a)
        sexp(a::AbstractDataArray{T}) where T<:$J = sexp($S,a)
        sexp(v::$J) = sexp($S,v)
    end
end

# Fallback: convert AbstractArray to VecSxp (R list)
sexp(a::AbstractArray) = sexp(VecSxp,a)

# Associative
sexp(d::Associative) = sexp(VecSxp,d)


for (J,S) in ((:Integer,:IntSxp),
                 (:AbstractFloat, :RealSxp),
                 (:Complex, :CplxSxp),
                 (:Bool, :LglSxp),
                 (:AbstractString, :StrSxp))
    @eval begin
        sexp(x::Nullable{T}) where T<:$J = sexp($S, x)
    end
end

# RawSxp
sexp(x::UInt8) = sexp(RawSxp, x)
sexp(a::AbstractArray{UInt8}) = sexp(RawSxp, a)
sexp(a::AbstractDataArray{UInt8}) = sexp(RawSxp, a)


sexp(v::CategoricalArray) = sexp(IntSxp, v)

# AxisArray
for (J,S) in ((:Integer,:IntSxp),
                 (:AbstractFloat, :RealSxp),
                 (:Complex, :CplxSxp),
                 (:Bool, :LglSxp),
                 (:AbstractString, :StrSxp))
    @eval sexp(aa::AxisArray{T}) where T<:$J = sexp($S, aa)
end

# Date
sexp(d::Date) = sexp(RealSxp, d)
sexp(d::Nullable{Date}) = sexp(RealSxp, d)
sexp(d::AbstractArray{Date}) = sexp(RealSxp, d)
sexp(d::AbstractDataArray{Date}) = sexp(RealSxp, d)

# DateTime
sexp(d::DateTime) = sexp(RealSxp, d)
sexp(d::Nullable{DateTime}) = sexp(RealSxp, d)
sexp(d::AbstractArray{DateTime}) = sexp(RealSxp, d)
sexp(d::AbstractDataArray{DateTime}) = sexp(RealSxp, d)


# Function
sexp(f::Function) = sexp(ClosSxp, f)
