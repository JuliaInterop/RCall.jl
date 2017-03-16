# logic for default rcopy

"""
`rcopy(r)` copies the contents of an R object into a corresponding canonical Julia type.
"""
rcopy(r::RObject) = rcopy(r.p)
RObject(s) = RObject(sexp(s))

# Fallbacks
rcopy{S<:Sxp}(::Type{Any}, s::Ptr{S}) = rcopy(s)

# NilSxp
sexp(::Void) = sexp(Const.NilValue)
rcopy(::Ptr{NilSxp}) = nothing

# SymSxp and CharSxp
sexp(s::Symbol) = sexp(SymSxp,s)
rcopy(s::SymSxpPtr) = rcopy(Symbol,s)
rcopy(s::CharSxpPtr) = rcopy(String,s)

# StrSxp
"Create a `StrSxp` from an Abstract String Array"
sexp{S<:AbstractString}(a::AbstractArray{S}) = sexp(StrSxp,a)
sexp(st::AbstractString) = sexp(StrSxp,st)

function rcopy(s::StrSxpPtr)
    if anyna(s)
        rcopy(NullableArray,s)
    elseif length(s) == 1
        rcopy(String,s)
    else
        rcopy(Array{String},s)
    end
end

# IntSxp, RealSxp, CplxSxp, LglSxp
for (J,S) in ((:Integer,:IntSxp),
                 (:Real, :RealSxp),
                 (:Complex, :CplxSxp),
                 (:Bool, :LglSxp))
    @eval begin
        sexp{T<:$J}(a::AbstractArray{T}) = sexp($S,a)
        sexp(v::$J) = sexp($S,v)
    end
end

function rcopy(s::IntSxpPtr)
    if isFactor(s)
        if anyna(s)
            rcopy(NullableCategoricalArray,s)
        else
            rcopy(CategoricalArray,s)
        end
    elseif anyna(s)
        rcopy(NullableArray{Int},s)
    elseif length(s) == 1
        rcopy(Cint,s)
    else
        rcopy(Array{Cint},s)
    end
end
function rcopy(s::RealSxpPtr)
    if anyna(s)
        rcopy(NullableArray{Float64},s)
    elseif length(s) == 1
        rcopy(Float64,s)
    else
        rcopy(Array{Float64},s)
    end
end
function rcopy(s::CplxSxpPtr)
    if anyna(s)
        rcopy(NullableArray{Complex128},s)
    elseif length(s) == 1
        rcopy(Complex128,s)
    else
        rcopy(Array{Complex128},s)
    end
end
function rcopy(s::LglSxpPtr)
    if anyna(s)
        rcopy(NullableArray{Bool},s)
    elseif length(s) == 1
        rcopy(Bool,s)
    else
        rcopy(BitArray,s)
    end
end

# VecSxp
sexp(a::AbstractArray) = sexp(VecSxp,a)
function rcopy(s::VecSxpPtr)
    if isFrame(s)
        rcopy(DataFrame,s)
    elseif isnull(getnames(s))
        rcopy(Array{Any},s)
    else
        rcopy(Dict{Symbol,Any},s)
    end
end
sexp{K,V<:AbstractString}(d::Associative{K,V}) = sexp(StrSxp,d)
sexp(d::Associative) = sexp(VecSxp,d)

# FunctionSxp
rcopy(s::FunctionSxpPtr) = rcopy(Function,s)

# TODO
rcopy(l::LangSxpPtr) = l
rcopy(r::RObject{LangSxp}) = r
