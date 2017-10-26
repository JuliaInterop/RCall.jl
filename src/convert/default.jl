# logic for default rcopy

"""
`rcopy(r)` copies the contents of an R object into a corresponding canonical Julia type.
"""
rcopy{S<:Sxp}(r::RObject{S}; kwargs...) = rcopy(r.p; kwargs...)

function rcopy{S<:Sxp}(s::Ptr{S}; kwargs...)
    protect(s)
    try
        class = rcopy(Symbol, getclass(s, true))
        if method_exists(rcopytype, Tuple{Type{RClass{class}}, Ptr{S}})
            return rcopy(rcopytype(RClass{class}, s), s; kwargs...)
        else
            return rcopy(rcopytype(s), s; kwargs...)
        end
    finally
        unprotect(1)
    end
end

# NilSxp
rcopy(::Ptr{NilSxp}) = nothing

# SymSxp and CharSxp
rcopy(s::Ptr{SymSxp}) = rcopy(Symbol,s)
rcopy(s::Ptr{CharSxp}) = rcopy(String,s)

# StrSxp
function rcopytype(s::Ptr{StrSxp})
    if anyna(s)
        DataArray{String}
    elseif length(s) == 1
        String
    else
        Array{String}
    end
end

function rcopytype(s::Ptr{IntSxp})
    if isFactor(s)
        PooledDataArray
    elseif anyna(s)
        DataArray{Int}
    elseif length(s) == 1
        Int
    else
        Array{Int}
    end
end

function rcopytype(s::Ptr{RealSxp})
    if anyna(s)
        DataArray{Float64}
    elseif length(s) == 1
        Float64
    else
        Array{Float64}
    end
end

function rcopytype(s::Ptr{CplxSxp})
    if anyna(s)
        DataArray{Complex128}
    elseif length(s) == 1
        Complex128
    else
        Array{Complex128}
    end
end

function rcopytype(s::Ptr{LglSxp})
    if anyna(s)
        DataArray{Bool}
    elseif length(s) == 1
        Bool
    else
        BitArray
    end
end

function rcopytype(s::Ptr{RawSxp})
    if anyna(s)
        DataArray{UInt8}
    elseif length(s) == 1
        UInt8
    else
        Array{UInt8}
    end
end

# Default behaviors of copying R vectors to arrays
for (J,S) in ((:Cint,:IntSxp),
                 (:Float64, :RealSxp),
                 (:Complex128, :CplxSxp),
                 (:Bool, :LglSxp),
                 (:String, :StrSxp),
                 (:UInt8, :RawSxp))
    @eval begin
        function rcopy(::Type{Vector},s::Ptr{$S})
            protect(s)
            try
                class = rcopy(Symbol, getclass(s, true))
                if method_exists(eltype, Tuple{Type{RClass{class}}, Ptr{$S}})
                    return rcopy(Vector{eltype(RClass{class}, s)}, s)
                else
                    return rcopy(Vector{$J},s)
                end
            finally
                unprotect(1)
            end
        end
        function rcopy(::Type{Array},s::Ptr{$S})
            protect(s)
            try
                class = rcopy(Symbol, getclass(s, true))
                if method_exists(eltype, Tuple{Type{RClass{class}}, Ptr{$S}})
                    return rcopy(Array{eltype(RClass{class}, s)}, s)
                else
                    return rcopy(Array{$J},s)
                end
            finally
                unprotect(1)
            end
        end
    end
end

# VecSxp
function rcopytype(s::Ptr{VecSxp}; kwargs...)
    if isFrame(s)
        DataFrame
    elseif isnull(getnames(s))
        Array{Any}
    else
        Dict{Symbol,Any}
    end
end

# FunctionSxp
rcopy{S<:FunctionSxp}(s::Ptr{S}) = rcopy(Function,s)

# TODO: LangSxp
rcopy(l::Ptr{LangSxp}) = RObject(l)
rcopy(r::RObject{LangSxp}) = r

# Fallback
rcopy(l) = RObject(l)


# logic of default sexp

"""
`sexp(x)` converts a Julia object `x` to a pointer to a corresponding Sxp Object.
"""

RObject(s) = RObject(sexp(s))

# nothing
sexp(::Void) = sexp(Const.NilValue)

# Symbol
sexp(s::Symbol) = sexp(SymSxp,s)

# DataFrame
sexp(d::AbstractDataFrame) = sexp(VecSxp, d)

# DataTable
# sexp(d::AbstractDataTable) = sexp(VecSxp, d)

# PooledDataArray
sexp(a::PooledDataArray) = sexp(IntSxp,a)
sexp{S<:AbstractString}(a::PooledDataArray{S}) = sexp(IntSxp,a)

# Number, Array and DataArray
for (J,S) in ((:Integer,:IntSxp),
                 (:AbstractFloat, :RealSxp),
                 (:Complex, :CplxSxp),
                 (:Bool, :LglSxp),
                 (:AbstractString, :StrSxp))
    @eval begin
        sexp{T<:$J}(a::AbstractArray{T}) = sexp($S,a)
        sexp{T<:$J}(a::DataArray{T}) = sexp($S,a)
        sexp(v::$J) = sexp($S,v)
    end
end

# Fallback: convert AbstractArray to VecSxp (R list)
sexp(a::AbstractArray) = sexp(VecSxp,a)

# Associative
sexp(d::Associative) = sexp(VecSxp,d)

# Nullable
sexp(x::Nullable{Union{}}) = sexp(NaInt)

for (J,S) in ((:Integer,:IntSxp),
                 (:AbstractFloat, :RealSxp),
                 (:Complex, :CplxSxp),
                 (:Bool, :LglSxp),
                 (:AbstractString, :StrSxp))
    @eval begin
        sexp{T<:$J}(x::Nullable{T}) = sexp($S, x)
        sexp{T<:$J}(v::NullableArray{T}) = sexp($S, v)
    end
end

# RawSxp
sexp(a::AbstractArray{UInt8}) = sexp(RawSxp, a)
sexp(a::DataArray{UInt8}) = sexp(RawSxp, a)
sexp(x::UInt8) = sexp(RawSxp, x)


if Pkg.installed("CategoricalArrays") < v"0.2.0"
    CAtypes = [:NullableCategoricalArray, :CategoricalArray]
else
    CAtypes = [:CategoricalArray]
end

for typ in CAtypes
    @eval sexp(v::$typ) = sexp(IntSxp, v)
end

# AxisArray and NamedArray
for (J,S) in ((:Integer,:IntSxp),
                 (:AbstractFloat, :RealSxp),
                 (:Complex, :CplxSxp),
                 (:Bool, :LglSxp),
                 (:AbstractString, :StrSxp))
    @eval sexp{T<:$J}(aa::AxisArray{T}) = sexp($S, aa)
    @eval sexp{T<:$J}(aa::NamedArray{T}) = sexp($S, aa)
end

# DataTime
sexp(d::Date) = sexp(RealSxp, d)
sexp(d::AbstractArray{Date}) = sexp(RealSxp, d)
sexp(d::NullableArray{Date}) = sexp(RealSxp, d)
sexp(d::DateTime) = sexp(RealSxp, d)
sexp(d::AbstractArray{DateTime}) = sexp(RealSxp, d)
sexp(d::NullableArray{DateTime}) = sexp(RealSxp, d)

# Function
sexp(f::Function) = sexp(ClosSxp, f)
