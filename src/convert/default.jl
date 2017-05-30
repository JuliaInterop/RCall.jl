# logic for default rcopy

"""
`rcopy(r)` copies the contents of an R object into a corresponding canonical Julia type.
"""
rcopy(r::RObject; kwargs...) = rcopy(r.p; kwargs...)

# Fallbacks
# convert Ptr{S} to Any would use the default conversions to allow
# automatic conversion of VecSxp objects, e.g., convert(Array{Any}, R"list(a=1, b=2)")
rcopy{S<:Sxp}(::Type{Any}, s::Ptr{S}) = rcopy(s)

# NilSxp
rcopy(::Ptr{NilSxp}) = nothing

# SymSxp and CharSxp
rcopy(s::Ptr{SymSxp}) = rcopy(Symbol,s)
rcopy(s::Ptr{CharSxp}) = rcopy(String,s)

# StrSxp
function rcopy(s::Ptr{StrSxp})
    if anyna(s)
        rcopy(DataArray{String},s)
    elseif length(s) == 1
        rcopy(String,s)
    else
        rcopy(Array{String},s)
    end
end

# IntSxp, RealSxp, CplxSxp, LglSxp
"""
It returns the corresponding element type when a RealSxp is converting to a julia object.
"""
function _eltype(s::Ptr{RealSxp})
    classes = rcopy(Vector, getclass(s))
    if "Date" in classes
        T = Date::DataType
    elseif "POSIXct" in classes && "POSIXt" in classes
        T = DateTime::DataType
    else
        T = Float64::DataType
    end
    return T
end

function rcopy(s::Ptr{IntSxp})
    if isFactor(s)
        rcopy(PooledDataArray,s)
    elseif anyna(s)
        rcopy(DataArray{Float64},s)
    elseif length(s) == 1
        rcopy(Cint,s)
    else
        rcopy(Array,s)
    end
end

function rcopy(s::Ptr{RealSxp})
    T = _eltype(s)
    if anyna(s)
        rcopy(DataArray{T},s)
    elseif length(s) == 1
        rcopy(T,s)
    else
        rcopy(Array{T},s)
    end
end
function rcopy(s::Ptr{CplxSxp})
    if anyna(s)
        rcopy(DataArray{Complex128},s)
    elseif length(s) == 1
        rcopy(Complex128,s)
    else
        rcopy(Array{Complex128},s)
    end
end
function rcopy(s::Ptr{LglSxp})
    if anyna(s)
        rcopy(DataArray{Bool},s)
    elseif length(s) == 1
        rcopy(Bool,s)
    else
        rcopy(BitArray,s)
    end
end

# Default behaviors of copying R vectors to arrays
rcopy(::Type{Vector},s::Ptr{IntSxp}) = rcopy(Vector{Cint},s)
rcopy(::Type{Array},s::Ptr{IntSxp}) = rcopy(Array{Cint},s)
function rcopy(::Type{Vector},s::Ptr{RealSxp})
    T = _eltype(s)
    rcopy(Vector{T},s)
end
function rcopy(::Type{Array},s::Ptr{RealSxp})
    T = _eltype(s)
    rcopy(Array{T},s)
end
rcopy(::Type{Vector},s::Ptr{CplxSxp}) = rcopy(Vector{Complex128},s)
rcopy(::Type{Array},s::Ptr{CplxSxp}) = rcopy(Array{Complex128},s)
rcopy(::Type{Array},s::Ptr{LglSxp}) = rcopy(Array{Bool},s)
rcopy(::Type{Vector},s::Ptr{LglSxp}) = rcopy(Vector{Bool},s)
rcopy(::Type{Vector}, s::Ptr{StrSxp}) = rcopy(Vector{String}, s)
rcopy(::Type{Array}, s::Ptr{StrSxp}) = rcopy(Array{String}, s)

# VecSxp
function rcopy(s::Ptr{VecSxp}; kwargs...)
    if isFrame(s)
        rcopy(DataFrame,s; kwargs...)
    elseif isnull(getnames(s))
        rcopy(Array{Any},s)
    else
        rcopy(Dict{Symbol,Any},s)
    end
end

# FunctionSxp
rcopy{S<:FunctionSxp}(s::Ptr{S}) = rcopy(Function,s)

# TODO: LangSxp
rcopy(l::Ptr{LangSxp}) = RObject(l)
rcopy(r::RObject{LangSxp}) = r


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
for typ in [:NullableCategoricalArray, :CategoricalArray]
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
