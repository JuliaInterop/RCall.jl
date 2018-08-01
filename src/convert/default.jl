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
rcopy(::Ptr{NilSxp}) = nothing

# SymSxp and CharSxp
rcopy(s::Ptr{SymSxp}) = rcopy(Symbol,s)
rcopy(s::Ptr{CharSxp}) = rcopy(String,s)

# StrSxp
function rcopytype(::Type{RClass{Sym}}, s::Ptr{StrSxp}) where Sym
    if anyna(s)
        length(s) == 1 ? Missing : Array{Union{String, Missing}}
    else
        length(s) == 1 ? String : Array{String}
    end
end
function eltype(::Type{RClass{Sym}}, s::Ptr{StrSxp}) where Sym
    if anyna(s)
        Union{String, Missing}
    else
        String
    end
end

function rcopytype(::Type{RClass{Sym}}, s::Ptr{IntSxp}) where Sym
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

function eltype(::Type{RClass{Sym}}, s::Ptr{IntSxp}) where Sym
    if anyna(s)
        Union{Int, Missing}
    else
        Int
    end
end

function rcopytype(::Type{RClass{Sym}}, s::Ptr{RealSxp}) where Sym
    if anyna(s)
        length(s) == 1 ? Missing : Array{Union{Float64, Missing}}
    else
        length(s) == 1 ? Float64 : Array{Float64}
    end
end
function eltype(::Type{RClass{Sym}}, s::Ptr{RealSxp}) where Sym
    if anyna(s)
        Union{Float64, Missing}
    else
        Float64
    end
end

function rcopytype(::Type{RClass{Sym}}, s::Ptr{CplxSxp}) where Sym
    if anyna(s)
        length(s) == 1 ? Missing : Array{Union{ComplexF64, Missing}}
    else
        length(s) == 1 ? ComplexF64 : Array{ComplexF64}
    end
end
function eltype(::Type{RClass{Sym}}, s::Ptr{CplxSxp}) where Sym
    if anyna(s)
        Union{ComplexF64, Missing}
    else
        ComplexF64
    end
end

function rcopytype(::Type{RClass{Sym}}, s::Ptr{LglSxp}) where Sym
    if anyna(s)
        length(s) == 1 ? Missing : Array{Union{Bool, Missing}}
    else
        length(s) == 1 ? Bool : BitArray
    end
end
function eltype(::Type{RClass{Sym}}, s::Ptr{LglSxp}) where Sym
    if anyna(s)
        Union{Bool, Missing}
    else
        Bool
    end
end

function rcopytype(::Type{RClass{Sym}}, s::Ptr{RawSxp}) where Sym
    if anyna(s)
        length(s) == 1 ? Missing : Array{Union{UInt8, Missing}}
    else
        length(s) == 1 ? UInt8 : Array{UInt8}
    end
end
function eltype(::Type{RClass{Sym}}, s::Ptr{RawSxp}) where Sym
    if anyna(s)
        Union{UInt8, Missing}
    else
        UInt8
    end
end

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

# LangSxp
rcopytype(::Type{RClass{:call}}, l::Ptr{LangSxp}) = Expr
rcopytype(::Type{RClass{Symbol("(")}}, l::Ptr{LangSxp}) = Expr
rcopytype(::Type{RClass{:formula}}, l::Ptr{LangSxp}) = Formula
# Fallback
rcopytype(::Type{RClass{Sym}}, s::Ptr{LangSxp}) where Sym = RObject

# Fallback for non SEXP
rcopy(r) = r

# logic of default sexp

"""
`sexp(x)` converts a Julia object `x` to a pointer to a corresponding Sxp Object.
"""
RObject(s) = RObject(sexp(s))

# nothing
sexp(::Nothing) = sexp(Const.NilValue)

# Missing
sexp(::Missing) = sexp(LglSxp, Const.NaInt)

# Symbol
sexp(s::Symbol) = sexp(SymSxp,s)

# DataFrame
sexp(d::AbstractDataFrame) = sexp(VecSxp, d)


# Number, Array
for (J,S) in ((:Integer,:IntSxp),
                 (:AbstractFloat, :RealSxp),
                 (:Complex, :CplxSxp),
                 (:Bool, :LglSxp),
                 (:AbstractString, :StrSxp),
                 (:UInt8, :RawSxp))
    @eval begin
        sexp(v::$J) = sexp($S,v)
        sexp(a::Array{Union{T, Missing}}) where T<:$J = sexp($S,a)
        sexp(a::AbstractArray{T}) where T<:$J = sexp($S,a)
    end
end

# Fallback: convert AbstractArray to VecSxp (R list)
sexp(a::AbstractArray) = sexp(VecSxp,a)

# AbstractDict
sexp(d::AbstractDict) = sexp(VecSxp,d)

# Function
sexp(f::Function) = sexp(ClosSxp, f)

# LangSxp
sexp(f::Formula) = sexp(LangSxp, f)
