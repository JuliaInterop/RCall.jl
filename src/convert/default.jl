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
rcopy(::Ptr{NilSxp}) = Nullable()

# SymSxp and CharSxp
rcopy(s::Ptr{SymSxp}) = rcopy(Symbol,s)
rcopy(s::Ptr{CharSxp}) = rcopy(String,s)

# StrSxp
function rcopytype(::Type{RClass{Sym}}, s::Ptr{StrSxp}) where Sym
    if length(s) == 1
        String
    elseif anyna(s)
        Array{Union{String, Missing}}
    else
        Array{String}
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
    if length(s) == 1
        Int
    elseif isFactor(s)
        CategoricalArray
    elseif anyna(s)
        Array{Union{Int, Missing}}
    else
        Array{Int}
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
    if length(s) == 1
        Float64
    elseif anyna(s)
        Array{Union{Float64, Missing}}
    else
        Array{Float64}
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
    if length(s) == 1
        Complex128
    elseif anyna(s)
        Array{Union{Complex128, Missing}}
    else
        Array{Complex128}
    end
end
function eltype(::Type{RClass{Sym}}, s::Ptr{CplxSxp}) where Sym
    if anyna(s)
        Union{Complex128, Missing}
    else
        Complex128
    end
end

function rcopytype(::Type{RClass{Sym}}, s::Ptr{LglSxp}) where Sym
    if length(s) == 1
        Bool
    elseif anyna(s)
        Array{Union{Bool, Missing}}
    else
        BitArray
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
    if length(s) == 1
        UInt8
    elseif anyna(s)
        Array{Union{UInt8, Missing}}
    else
        Array{UInt8}
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
                 (:AbstractString, :StrSxp),
                 (:UInt8, :RawSxp))
    @eval begin
        sexp(v::$J) = sexp($S,v)
        sexp(x::Nullable{T}) where T<:$J = sexp($S, x)
        sexp(a::Array{Union{T, Missing}}) where T<:$J = sexp($S,a)
        sexp(a::AbstractArray{T}) where T<:$J = sexp($S,a)
        sexp(a::AbstractDataArray{T}) where T<:$J = sexp($S,a)
    end
end

# Fallback: convert AbstractArray to VecSxp (R list)
sexp(a::AbstractArray) = sexp(VecSxp,a)

# Associative
sexp(d::Associative) = sexp(VecSxp,d)

# Function
sexp(f::Function) = sexp(ClosSxp, f)
