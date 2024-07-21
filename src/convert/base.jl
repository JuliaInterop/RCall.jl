convert(::Type{T}, r::RObject{S}) where {T, S<:Sxp} = rcopy(T, r.p)
convert(::Type{Any}, r::RObject{S}) where S<:Sxp = r
convert(::Type{RObject}, r::RObject{S}) where S<:Sxp = r
convert(::Type{RObject{S}}, r::RObject{S}) where S<:Sxp = r

# conversion between numbers which understands different NAs
function rcopy(::Type{T}, x::R) where {T<:Number, R<:Number}
    if (R == Float64 && !isnan(x)) || (R == Int32 && !isNA(x))
        return T(x)
    elseif T <: AbstractFloat && R == Int32
        return T(NaN)
    else
        return T(x)
    end
end

# conversion to Base Julia types
rcopy(::Type{T},r::RObject; kwargs...) where T = rcopy(T, r.p; kwargs...)
# convert Ptr{S} to Any would use the default conversions to allow
# automatic conversion of VecSxp objects, e.g., convert(Array{Any}, R"list(a=1, b=2)")
rcopy(::Type{T}, s::Ptr{S}) where {S<:Sxp, T<:Any} = rcopy(s)
rcopy(::Type{RObject}, s::Ptr{S}) where S<:Sxp = RObject(s)


# Missing
rcopy(::Type{Missing}, ::Ptr{S}) where S<:Sxp = missing

# NilSxp
rcopy(::Type{T}, ::Ptr{NilSxp}) where T = nothing
rcopy(::Type{T}, ::Ptr{NilSxp}) where T<:AbstractArray = T()

# SymSxp
function rcopy(::Type{T},s::Ptr{SymSxp}) where T<:Union{Symbol,AbstractString}
    rcopy(T, ccall((:PRINTNAME, libR), Ptr{CharSxp}, (Ptr{SymSxp},), s))
end

# CharSxp
function rcopy(::Type{T},s::Ptr{CharSxp}) where T<:AbstractString
    c = ccall((:R_CHAR, libR), Ptr{Cchar}, (Ptr{CharSxp},), s)
    convert(T, unsafe_string(c))
end
rcopy(::Type{Symbol},s::Ptr{CharSxp}) = Symbol(rcopy(AbstractString,s))
rcopy(::Type{Int}, s::Ptr{CharSxp}) = parse(Int, rcopy(s))


# sexp to Array{T}
for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp, :RawSxp, :VecSxp)
    @eval begin
        function rcopy(::Type{Array{T}}, s::Ptr{$S}) where T
            protect(s)
            v = try
                T[rcopy(T,e) for e in s]
            finally
                unprotect(1)
            end
            reshape(v,size(s))
        end
        function rcopy(::Type{Vector{T}}, s::Ptr{$S}) where T
            protect(s)
            v = try
                T[rcopy(T,e) for e in s]
            finally
                unprotect(1)
            end
            v
        end
    end
end

# IntSxp, RealSxp, CplxSxp, LglSxp, RawSxp scalar conversion
for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :RawSxp)
    @eval begin
        function rcopy(::Type{T},s::Ptr{$S}) where T<:Number
            length(s) == 1 || error("length of s must be 1.")
            rcopy(T,s[1])
        end
    end
end

# IntSxp, RealSxp, CplxSxp, RawSxp to their corresponding Julia types.
for (J,S) in ((:Integer,:IntSxp),
                 (:AbstractFloat, :RealSxp),
                 (:Complex, :CplxSxp),
                 (:UInt8, :RawSxp))
    @eval begin
        function rcopy(::Type{Vector{T}},s::Ptr{$S}) where T<:$J
            a = Array{T}(undef, length(s))
            copyto!(a,unsafe_vec(s))
            a
        end
        function rcopy(::Type{Array{T}},s::Ptr{$S}) where T<:$J
            a = Array{T}(undef, size(s)...)
            copyto!(a,unsafe_vec(s))
            a
        end
    end
end

# LglSxp
function rcopy(::Type{Cint},s::Ptr{LglSxp})
    length(s) == 1 || error("length of s must be 1.")
    convert(Cint, s[1])
end
function rcopy(::Type{Bool},s::Ptr{LglSxp})
    length(s) == 1 || error("length of s must be 1.")
    s[1] == 1
end

function rcopy(::Type{Vector{Cint}},s::Ptr{LglSxp})
    a = Array{Cint}(undef, length(s))
    copyto!(a,unsafe_vec(s))
    a
end
function rcopy(::Type{Vector{Bool}},s::Ptr{LglSxp})
    a = Array{Bool}(undef, length(s))
    v = unsafe_vec(s)
    for i in eachindex(a, v)
        a[i] = v[i] != 0
    end
    a
end
function rcopy(::Type{BitVector},s::Ptr{LglSxp})
    a = BitArray(undef, length(s))
    v = unsafe_vec(s)
    for i in eachindex(a, v)
        a[i] = v[i] != 0
    end
    a
end
function rcopy(::Type{Array{Cint}},s::Ptr{LglSxp})
    a = Array{Cint}(undef, size(s)...)
    copyto!(a,unsafe_vec(s))
    a
end
function rcopy(::Type{Array{Bool}},s::Ptr{LglSxp})
    a = Array{Bool}(undef, size(s)...)
    v = unsafe_vec(s)
    for i in eachindex(a, v)
        a[i] = v[i] != 0
    end
    a
end
function rcopy(::Type{BitArray},s::Ptr{LglSxp})
    a = BitArray(undef, size(s)...)
    v = unsafe_vec(s)
    for i in eachindex(a, v)
        a[i] = v[i] != 0
    end
    a
end

# StrSxp
function rcopy(::Type{Symbol}, s::Ptr{StrSxp})
    length(s) == 1 || error("length of s must be 1.")
    rcopy(Symbol,s[1])
end
function rcopy(::Type{T},s::Ptr{StrSxp}) where T<:AbstractString
    length(s) == 1 || error("length of s must be 1.")
    rcopy(T,s[1])
end

# VecSxp
rcopy(::Type{Array}, s::Ptr{VecSxp}) = rcopy(Array{Any}, s)
rcopy(::Type{Vector}, s::Ptr{VecSxp}) = rcopy(Vector{Any}, s)
function rcopy(::Type{A}, s::Ptr{VecSxp};
               normalizenames::Bool=true) where A<:AbstractDict
    protect(s)
    a = A()
    try
        K = keytype(a)
        V = valtype(a)
        if normalizenames && (K <: AbstractString || K <: Symbol)
            for k in rcopy(Array{String}, getnames(s))
                a[K(replace(k, "." => "_"))] = rcopy(V, s[k])
            end
        else
            for k in rcopy(Array{String}, getnames(s))
                if K <: AbstractString || K <: Symbol
                    key = K(k)
                else
                    key = convert(K, k)
                end
                a[key] = rcopy(V, s[k])
            end
        end
    finally
        unprotect(1)
    end
    a
end

# Function wrapper which allows for dispatch
struct RFunction{F}
    f::F
end
(rf::RFunction)(args...) = rcopy(rcall_p(rf.f,args...))
        
# FunctionSxp
function rcopy(::Type{Function}, s::Ptr{S}) where S<:FunctionSxp
    # prevent s begin gc'ed
    r = RObject(s)
    RFunction(r)
end
function rcopy(::Type{Function}, r::RObject{S}) where S<:FunctionSxp
    RFunction(r)
end

# conversion from Base Julia types

robject(T::RClass, s) = RObject(sexp(T, s))
robject(T::Symbol, s) = RObject(sexp(RClass{T}, s))
robject(T::String, s) = RObject(sexp(RClass{Symbol(T)}, s))

# fallback
sexp(::T, s::Ptr{S}) where {T, S<:Sxp} = s
sexp(::T, r::RObject{S}) where {T, S<:Sxp} = r

# nothing / missing
sexp(::Type{NilSxp}, ::Nothing) = sexp(Const.NilValue)
sexp(::Type{C}, ::Missing) where C<:RClass = naeltype(C)

# symbol
sexp(::Type{SymSxp}, s::Symbol) = sexp(SymSxp, string(s))
sexp(::Type{CharSxp}, s::Symbol) = sexp(CharSxp, string(s))
sexp(::Type{RClass{:character}}, s::Symbol) = sexp(RClass{:character}, sexp(CharSxp, s))


# number and numeric array
for (J, S, C) in ((:Integer, :IntSxp, :integer),
                 (:AbstractFloat, :RealSxp, :numeric),
                 (:Complex, :CplxSxp, :complex),
                 (:Bool, :LglSxp, :logical),
                 (:UInt8, :RawSxp, :raw))
    @eval begin
        # Could use Rf_Scalar... methods, but see weird error on Appveyor Windows for Complex.
        function sexp(::Type{RClass{$(QuoteNode(C))}}, v::$J)
            ra = allocArray($S,1)
            unsafe_store!(dataptr(ra),convert(eltype($S),v))
            ra
        end
        function sexp(::Type{RClass{$(QuoteNode(C))}}, a::AbstractArray{T}) where T<:$J
            ra = allocArray($S, size(a)...)
            copyto!(unsafe_vec(ra),a)
            ra
        end
    end
end

# additional methods for bool
sexp(::Type{RClass{:logical}}, v::Cint) =
    ccall((:Rf_ScalarLogical,libR),Ptr{LglSxp},(Cint,),v)
function sexp(::Type{RClass{:logical}}, a::AbstractArray{Cint})
    ra = allocArray(LglSxp, size(a)...)
    copy!(unsafe_vec(ra),a)
    ra
end

# String
sexp(::Type{SymSxp}, s::AbstractString) = ccall((:Rf_install, libR), Ptr{SymSxp}, (Ptr{UInt8},), s)
sexp(::Type{CharSxp}, st::String) = ccall((:Rf_mkCharLenCE, libR), Ptr{CharSxp}, (Ptr{UInt8}, Cint, Cint), st, sizeof(st), isascii(st) ? 0 : 1)
sexp(::Type{CharSxp}, st::AbstractString) = sexp(CharSxp, String(st))
sexp(::Type{RClass{:character}}, s::Ptr{CharSxp}) = ccall((:Rf_ScalarString,libR),Ptr{StrSxp},(Ptr{CharSxp},),s)
sexp(::Type{RClass{:character}},st::AbstractString) = sexp(RClass{:character}, sexp(CharSxp,st))
function sexp(::Type{RClass{:character}}, a::AbstractArray{T}) where T<:AbstractString
    ra = protect(allocArray(StrSxp, size(a)...))
    try
        # we want this to work even if a doesn't use one-based indexing
        # we only care about ra having the same length (which it does)
        for (i, idx) in zip(eachindex(ra), eachindex(a))
            ra[i] = a[idx]
        end
    finally
        unprotect(1)
    end
    ra
end

# AbstractDict to VecSxp
# R does not have a native dictionary type, but named lists is often
# used to this effect.
function sexp(::Type{RClass{:list}}, d::AbstractDict)
    n = length(d)
    vs = protect(allocArray(VecSxp,n))
    ks = protect(allocArray(StrSxp,n))
    try
        for (i,(k,v)) in enumerate(d)
            ks[i] = string(k)
            vs[i] = v
        end
        setnames!(vs,ks)
    finally
        unprotect(2)
    end
    vs
end

# AbstractArray to VecSxp
function sexp(::Type{RClass{:list}}, a::AbstractArray)
    ra = protect(allocArray(VecSxp, size(a)...))
    try
        # we want this to work even if a doesn't use one-based indexing
        # we only care about ra having the same length (which it does)
        for (i, idx) in zip(eachindex(ra), eachindex(a))
            ra[i] = a[idx]
        end
    finally
        unprotect(1)
    end
    ra
end

# Function

# check src/callback.jl for `sexp(::ClosSxp, ::Function)`
