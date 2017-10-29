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

#  force vector conversion in dataframe
if Pkg.installed("CategoricalArrays") < v"0.2.0"
    function rcopy(::Type{AbstractArray}, s::Ptr{S}) where S<:Sxp
        protect(s)
        try
            if isFactor(s)
                return anyna(s) ? rcopy(NullableCategoricalArray, s) : rcopy(CategoricalArray, s)
            else
                return anyna(s) ? rcopy(DataArray, s) : rcopy(Array, s)
            end
        finally
            unprotect(1)
        end
    end
else
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
end

# NilSxp
rcopy(::Ptr{NilSxp}) = null

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

if Pkg.installed("CategoricalArrays") < v"0.2.0"
    function rcopytype(::Type{RClass{Sym}}, s::Ptr{IntSxp}) where Sym
        if length(s) == 1
            Int
        elseif isFactor(s)
            anyna(s) ? NullableCategoricalArray : CategoricalArray
        elseif anyna(s)
            DataArray{Int}
        else
            Array{Int}
        end
    end
else
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
        Dict{Symbol,Any}
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

# Null
sexp(x::Null) = sexp(LglSxp, Const.NaInt)

# Nullable
sexp(x::Nullable{Union{}}) = sexp(LglSxp, Const.NaInt)

# Symbol
sexp(s::Symbol) = sexp(SymSxp,s)

# DataFrame
sexp(d::AbstractDataFrame) = sexp(VecSxp, d)

# DataTable
# sexp(d::AbstractDataTable) = sexp(VecSxp, d)


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
        sexp(v::NullableArray{T}) where T<:$J = sexp($S, v)
    end
end

# RawSxp
sexp(a::AbstractArray{UInt8}) = sexp(RawSxp, a)
sexp(a::AbstractDataArray{UInt8}) = sexp(RawSxp, a)
sexp(a::NullableArray{UInt8}) = sexp(RawSxp, a)
sexp(x::UInt8) = sexp(RawSxp, x)


if Pkg.installed("CategoricalArrays") < v"0.2.0"
    CAtypes = [:NullableCategoricalArray, :CategoricalArray]
else
    CAtypes = [:CategoricalArray]
end

for typ in CAtypes
    @eval sexp(v::$typ) = sexp(IntSxp, v)
end

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
sexp(d::AbstractArray{Date}) = sexp(RealSxp, d)
sexp(d::Nullable{Date}) = sexp(RealSxp, d)
sexp(d::NullableArray{Date}) = sexp(RealSxp, d)

# DateTime
sexp(d::DateTime) = sexp(RealSxp, d)
sexp(d::AbstractArray{DateTime}) = sexp(RealSxp, d)
sexp(d::Nullable{DateTime}) = sexp(RealSxp, d)
sexp(d::NullableArray{DateTime}) = sexp(RealSxp, d)


# Function
sexp(f::Function) = sexp(ClosSxp, f)
