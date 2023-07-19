# logic for default rcopy

"""
`rcopy(r)` copies the contents of an R object into a corresponding canonical Julia type.
"""
rcopy(r::RObject{S}; kwargs...) where S<:Sxp = rcopy(r.p; kwargs...)

function rcopy(s::Ptr{S}; kwargs...) where S<:Sxp
    protect(s)
    try
        for class in rcopy(Array{Symbol}, getclass(s))
            T = rcopytype(RClass{class}, s)
            if T != RObject
                return rcopy(T, s; kwargs...)
            end
        end
        T = rcopytype(RClass{:default}, s)
        return rcopy(T, s; kwargs...)
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
            return rcopy(Array, s)
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
                for class in rcopy(Array{Symbol}, getclass(s))
                    T = rcopytype(RClass{class}, s)
                    if T != RObject
                        return rcopy(Vector{eltype(RClass{class}, s)}, s)
                    end
                end
                return rcopy(Vector{eltype(RClass{:default}, s)}, s)
            finally
                unprotect(1)
            end
        end
        function rcopy(::Type{Array},s::Ptr{$S})
            protect(s)
            try
                for class in rcopy(Array{Symbol}, getclass(s))
                    T = rcopytype(RClass{class}, s)
                    if T != RObject
                        return rcopy(Array{eltype(RClass{class}, s)}, s)
                    end
                end
                return rcopy(Array{eltype(RClass{:default}, s)}, s)
            finally
                unprotect(1)
            end
        end
    end
end

# NilSxp
rcopy(::Ptr{NilSxp}) = nothing

# SymSxp and CharSxp
rcopy(s::Ptr{SymSxp}) = rcopy(Symbol,s)
rcopy(s::Ptr{CharSxp}) = rcopy(String,s)

# StrSxp
function rcopytype(::Type{RClass{:default}}, s::Ptr{StrSxp})
    if anyna(s)
        length(s) == 1 ? Missing : Array{Union{String, Missing}}
    else
        length(s) == 1 ? String : Array{String}
    end
end
function eltype(::Type{RClass{:default}}, s::Ptr{StrSxp})
    if anyna(s)
        Union{String, Missing}
    else
        String
    end
end

function rcopytype(::Type{RClass{:default}}, s::Ptr{IntSxp})
    if isFactor(s)
        CategoricalArray
    else
        if anyna(s)
            length(s) == 1 ? Missing : Array{Union{Int, Missing}}
        else
            length(s) == 1 ? Int : Array{Int}
        end
    end
end

function eltype(::Type{RClass{:default}}, s::Ptr{IntSxp})
    if anyna(s)
        Union{Int, Missing}
    else
        Int
    end
end

function rcopytype(::Type{RClass{:default}}, s::Ptr{RealSxp})
    if anyna(s)
        length(s) == 1 ? Missing : Array{Union{Float64, Missing}}
    else
        length(s) == 1 ? Float64 : Array{Float64}
    end
end
function eltype(::Type{RClass{:default}}, s::Ptr{RealSxp})
    if anyna(s)
        Union{Float64, Missing}
    else
        Float64
    end
end

function rcopytype(::Type{RClass{:default}}, s::Ptr{CplxSxp})
    if anyna(s)
        length(s) == 1 ? Missing : Array{Union{ComplexF64, Missing}}
    else
        length(s) == 1 ? ComplexF64 : Array{ComplexF64}
    end
end
function eltype(::Type{RClass{:default}}, s::Ptr{CplxSxp})
    if anyna(s)
        Union{ComplexF64, Missing}
    else
        ComplexF64
    end
end

function rcopytype(::Type{RClass{:default}}, s::Ptr{LglSxp})
    if anyna(s)
        length(s) == 1 ? Missing : Array{Union{Bool, Missing}}
    else
        length(s) == 1 ? Bool : BitArray
    end
end
function eltype(::Type{RClass{:default}}, s::Ptr{LglSxp})
    if anyna(s)
        Union{Bool, Missing}
    else
        Bool
    end
end

function rcopytype(::Type{RClass{:default}}, s::Ptr{RawSxp})
    if anyna(s)
        length(s) == 1 ? Missing : Array{Union{UInt8, Missing}}
    else
        length(s) == 1 ? UInt8 : Array{UInt8}
    end
end
function eltype(::Type{RClass{:default}}, s::Ptr{RawSxp})
    if anyna(s)
        Union{UInt8, Missing}
    else
        UInt8
    end
end

# VecSxp
function rcopytype(::Type{RClass{:default}}, s::Ptr{VecSxp})
    if isFrame(s)
        DataFrame
    elseif isnull(getnames(s))
        Array{Any}
    else
        OrderedDict{Symbol,Any}
    end
end

# FunctionSxp
rcopytype(::Type{RClass{:function}}, s::Ptr{S}) where S<:FunctionSxp = Function

# LangSxp
rcopytype(::Type{RClass{:call}}, l::Ptr{LangSxp}) = Expr
rcopytype(::Type{RClass{Symbol("(")}}, l::Ptr{LangSxp}) = Expr
rcopytype(::Type{RClass{:formula}}, l::Ptr{LangSxp}) = FormulaTerm

# Fallback
rcopytype(::T, s::Ptr{S}) where {T, S<:Sxp} = RObject

# Fallback for non SEXP
rcopy(r) = r

# logic of default sexp

"""
`robject(x)` converts a Julia object `x` to a corresponding RObject implicitly. Explicit conversions
could be called with `robject(<R Class>, x)`.
"""
robject(s) = RObject(s)
RObject(s) = RObject(sexp(s))

"""
`sexp(x)` converts a Julia object `x` to a pointer to a corresponding Sxp Object.
"""
sexp(s) = sexp(sexpclass(s), s)


# Nothing / Missing
sexpclass(::Nothing) = NilSxp
sexpclass(::Missing) = RClass{:logical}

# Symbol
sexpclass(s::Symbol) = SymSxp

# DataFrame
sexpclass(d::AbstractDataFrame) = RClass{:list}


# Number, Array
for (J, C) in ((:Integer,:integer),
                 (:AbstractFloat, :numeric),
                 (:Complex, :complex),
                 (:Bool, :logical),
                 (:AbstractString, :character),
                 (:UInt8, :raw))
    @eval begin
        sexpclass(v::$J) = RClass{$(QuoteNode(C))}
        sexpclass(a::AbstractArray{Union{T, Missing}}) where T<:$J = RClass{$(QuoteNode(C))}
        sexpclass(a::AbstractArray{T}) where T<:$J = RClass{$(QuoteNode(C))}
    end
end

# Fallback: entire column of missing to NA
# R assigns these to logical by default, although if it's all missing, it doesn't matter much
sexpclass(a::AbstractArray{Missing}) = RClass{:logical}

# Fallback: convert AbstractArray to VecSxp (R list)
sexpclass(a::AbstractArray) = RClass{:list}

# AbstractDict
sexpclass(d::AbstractDict) = RClass{:list}

# Function
sexpclass(f::Function) = RClass{:function}

# LangSxp
sexpclass(f::FormulaTerm) = RClass{:formula}


# Date
sexpclass(d::Date) = RClass{:Date}
sexpclass(d::AbstractArray{Union{Date, Missing}}) = RClass{:Date}
sexpclass(d::AbstractArray{Date}) = RClass{:Date}

# DateTime
sexpclass(d::DateTime) = RClass{:POSIXct}
sexpclass(d::AbstractArray{Union{DateTime, Missing}}) = RClass{:POSIXct}
sexpclass(d::AbstractArray{DateTime}) = RClass{:POSIXct}

# CategoricalArray
sexpclass(v::CategoricalArray) = RClass{:factor}
sexpclass(v::SubArray{<:Any, <:Any, <:CategoricalArray}) = RClass{:factor}
