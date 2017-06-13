# logic for default rcopy

"""
`rcopy(r)` copies the contents of an R object into a corresponding canonical Julia type.
"""
rcopy{S<:Sxp}(r::RObject{S}; kwargs...) = rcopy(r.p; kwargs...)

function rcopy{S<:Sxp}(s::Ptr{S}; kwargs...)
    protect(s)
    try
        class = rcopy(Symbol, getclass(s, true))
        if method_exists(rcopy, Tuple{Type{RClass{class}}, Ptr{S}})
            return rcopy(RClass{class}, s; kwargs...)
        else
            return rcopy(RClass{:default}, s; kwargs...)
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
function rcopy(::Type{RClass{:default}}, s::Ptr{StrSxp})
    if anyna(s)
        rcopy(DataArray{String},s)
    elseif length(s) == 1
        rcopy(String,s)
    else
        rcopy(Array{String},s)
    end
end

function rcopy(::Type{RClass{:default}}, s::Ptr{IntSxp})
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

function rcopy(::Type{RClass{:default}}, s::Ptr{RealSxp})
    if anyna(s)
        rcopy(DataArray{Float64},s)
    elseif length(s) == 1
        rcopy(Float64,s)
    else
        rcopy(Array{Float64},s)
    end
end

function rcopy(::Type{RClass{:default}}, s::Ptr{CplxSxp})
    if anyna(s)
        rcopy(DataArray{Complex128},s)
    elseif length(s) == 1
        rcopy(Complex128,s)
    else
        rcopy(Array{Complex128},s)
    end
end

function rcopy(::Type{RClass{:default}}, s::Ptr{LglSxp})
    if anyna(s)
        rcopy(DataArray{Bool},s)
    elseif length(s) == 1
        rcopy(Bool,s)
    else
        rcopy(BitArray,s)
    end
end

# Default behaviors of copying R vectors to arrays
for (J,S) in ((:Cint,:IntSxp),
                 (:Float64, :RealSxp),
                 (:Complex128, :CplxSxp),
                 (:Bool, :LglSxp),
                 (:String, :StrSxp))
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
function rcopy(::Type{RClass{:default}}, s::Ptr{VecSxp}; kwargs...)
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
