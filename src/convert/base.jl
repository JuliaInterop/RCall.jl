struct RClass{Symbol} end

# conversion to Base Julia types

rcopy(::Type{T},r::RObject; kwargs...) where T = rcopy(T, r.p; kwargs...)
# make sure convert doesn't invoke rcopy in the following situations
convert(::Type{Any}, r::RObject{S}) where S<:Sxp = r
convert(::Type{RObject}, r::RObject{S}) where S<:Sxp = r
convert(::Type{RObject{S}}, r::RObject{S}) where S<:Sxp = r
# allow `Int(R"1+1")`
convert(::Type{T}, r::RObject{S}) where {T, S<:Sxp} = rcopy(T, r.p)

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

# Fallbacks
# convert Ptr{S} to Any would use the default conversions to allow
# automatic conversion of VecSxp objects, e.g., convert(Array{Any}, R"list(a=1, b=2)")
rcopy(::Type{Any}, s::Ptr{S}) where S<:Sxp = rcopy(s)

# NilSxp
rcopy(::Type{Any}, ::Ptr{NilSxp}) = null
rcopy(::Type{T}, ::Ptr{NilSxp}) where T = null
rcopy(::Type{T}, ::Ptr{NilSxp}) where T<:AbstractArray = T()

# SymSxp
rcopy(::Type{T},s::Ptr{SymSxp}) where T<:Union{Symbol,AbstractString} = rcopy(T, sexp(unsafe_load(s).name))

# CharSxp
rcopy(::Type{T},s::Ptr{CharSxp}) where T<:AbstractString = convert(T, String(unsafe_vec(s)))
rcopy(::Type{Symbol},s::Ptr{CharSxp}) = Symbol(rcopy(AbstractString,s))
rcopy(::Type{Int}, s::Ptr{CharSxp}) = parse(Int, rcopy(s))

# Default behaviors of copying R vectors to arrays

for (J,S) in ((:Int,:IntSxp),
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

# IntSxp, RealSxp, CplxSxp, LglSxp, StrSxp, VecSxp to Array{T}
for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp, :VecSxp)
    @eval begin
        function rcopy(::Type{Array{T}}, s::Ptr{$S}) where T
            protect(s)
            v = T[rcopy(T,e) for e in s]
            ret = reshape(v,size(s))
            unprotect(1)
            ret
        end
        function rcopy(::Type{Vector{T}}, s::Ptr{$S}) where T
            protect(s)
            ret = T[rcopy(T,e) for e in s]
            unprotect(1)
            ret
        end
    end
end

# IntSxp, RealSxp, CplxSxp, LglSxp scalar conversion
for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp)
    @eval begin
        function rcopy(::Type{T},s::Ptr{$S}) where T<:Number
            length(s) == 1 || error("length of s must be 1.")
            rcopy(T,s[1])
        end
    end
end

# IntSxp, RealSxp, CplxSxp to their corresponding Julia types.
for (J,S) in ((:Integer,:IntSxp),
                 (:AbstractFloat, :RealSxp),
                 (:Complex, :CplxSxp))
    @eval begin
        function rcopy(::Type{Vector{T}},s::Ptr{$S}) where T<:$J
            a = Array{T}(length(s))
            copy!(a,unsafe_vec(s))
            a
        end
        function rcopy(::Type{Array{T}},s::Ptr{$S}) where T<:$J
            a = Array{T}(size(s)...)
            copy!(a,unsafe_vec(s))
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
    a = Array{Cint}(length(s))
    copy!(a,unsafe_vec(s))
    a
end
function rcopy(::Type{Vector{Bool}},s::Ptr{LglSxp})
    a = Array{Bool}(length(s))
    v = unsafe_vec(s)
    for i = 1:length(a)
        a[i] = v[i] != 0
    end
    a
end
function rcopy(::Type{BitVector},s::Ptr{LglSxp})
    a = BitArray(length(s))
    v = unsafe_vec(s)
    for i = 1:length(a)
        a[i] = v[i] != 0
    end
    a
end
function rcopy(::Type{Array{Cint}},s::Ptr{LglSxp})
    a = Array{Cint}(size(s)...)
    copy!(a,unsafe_vec(s))
    a
end
function rcopy(::Type{Array{Bool}},s::Ptr{LglSxp})
    a = Array{Bool}(size(s)...)
    v = unsafe_vec(s)
    for i = 1:length(a)
        a[i] = v[i] != 0
    end
    a
end
function rcopy(::Type{BitArray},s::Ptr{LglSxp})
    a = BitArray(size(s)...)
    v = unsafe_vec(s)
    for i = 1:length(a)
        a[i] = v[i] != 0
    end
    a
end

# RawSxp
function rcopy(::Type{UInt8},s::Ptr{RawSxp})
    length(s) == 1 || error("length of s must be 1.")
    s[1]
end

function rcopy(::Type{Vector{UInt8}},s::Ptr{RawSxp})
    a = Array{UInt8}(length(s))
    copy!(a,unsafe_vec(s))
    a
end

function rcopy(::Type{Array{UInt8}},s::Ptr{RawSxp})
    a = Array{UInt8}(size(s)...)
    copy!(a,unsafe_vec(s))
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
function rcopy(::Type{A}, s::Ptr{VecSxp}) where A<:Associative
    protect(s)
    local a
    try
        a = A()
        K = keytype(a)
        V = valtype(a)
        for (k,v) in zip(getnames(s),s)
            a[rcopy(K,k)] = rcopy(V,v)
        end
    finally
        unprotect(1)
    end
    a
end


# FunctionSxp
function rcopy(::Type{Function}, s::Ptr{S}) where S<:FunctionSxp
    (args...) -> rcopy(rcall_p(s,args...))
end
function rcopy(::Type{Function}, r::RObject{S}) where S<:FunctionSxp
    (args...) -> rcopy(rcall_p(r,args...))
end


# conversion from Base Julia types

# nothing
sexp(::Type{S}, ::Void) where S<:Sxp = sexp(Const.NilValue)

# null
sexp(::Type{S}, ::Null) where S<:Sxp = naeltype($S)

# nullable
function sexp(::Type{S}, s::Nullable) where S<:Sxp
    if isnull(s)
        naeltype(S)
    else
        sexp(S, s.value)
    end
end

# symbol
sexp(::Type{SymSxp}, s::Symbol) = sexp(SymSxp,string(s))
sexp(::Type{CharSxp}, sym::Symbol) = sexp(CharSxp, string(sym))
sexp(::Type{StrSxp},s::Symbol) = sexp(StrSxp,sexp(CharSxp,s))


# number and numeric array
for (J,S) in ((:Integer,:IntSxp),
                 (:AbstractFloat, :RealSxp),
                 (:Complex, :CplxSxp))
    @eval begin
        # Could use Rf_Scalar... methods, but see weird error on Appveyor Windows for Complex.
        function sexp(::Type{$S},v::$J)
            ra = allocArray($S,1)
            unsafe_store!(dataptr(ra),convert(eltype($S),v))
            ra
        end
        function sexp(::Type{$S}, a::AbstractArray{T}) where T<:$J
            ra = allocArray($S, size(a)...)
            copy!(unsafe_vec(ra),a)
            ra
        end
    end
end

# bool and boolean array, handle seperately
sexp(::Type{LglSxp},v::Union{Bool,Cint}) =
    ccall((:Rf_ScalarLogical,libR),Ptr{LglSxp},(Cint,),v)
function sexp(::Type{LglSxp}, a::AbstractArray{T}) where T<:Union{Bool,Cint}
    ra = allocArray(LglSxp, size(a)...)
    copy!(unsafe_vec(ra),a)
    ra
end

# UInt8 to Raw vector
function sexp(::Type{RawSxp},v::UInt8)
    ra = allocArray(RawSxp,1)
    unsafe_store!(dataptr(ra),v)
    ra
end
function sexp(::Type{RawSxp}, a::AbstractArray{UInt8})
    ra = allocArray(RawSxp, size(a)...)
    copy!(unsafe_vec(ra),a)
    ra
end

# String
sexp(::Type{SymSxp}, s::AbstractString) = ccall((:Rf_install, libR), Ptr{SymSxp}, (Ptr{UInt8},), s)
sexp(::Type{CharSxp}, st::String) =
    ccall((:Rf_mkCharLenCE, libR), Ptr{CharSxp},
          (Ptr{UInt8}, Cint, Cint), st, sizeof(st), isascii(st) ? 0 : 1)
sexp(::Type{CharSxp}, st::AbstractString) = sexp(CharSxp, String(st))
sexp(::Type{StrSxp}, s::Ptr{CharSxp}) = ccall((:Rf_ScalarString,libR),Ptr{StrSxp},(Ptr{CharSxp},),s)
sexp(::Type{StrSxp},st::AbstractString) = sexp(StrSxp,sexp(CharSxp,st))
function sexp(::Type{StrSxp}, a::AbstractArray{T}) where T<:AbstractString
    ra = protect(allocArray(StrSxp, size(a)...))
    try
        for i in 1:length(a)
            ra[i] = a[i]
        end
    finally
        unprotect(1)
    end
    ra
end

# Associative to VecSxp
# R does not have a native dictionary type, but named lists is often
# used to this effect.
function sexp(::Type{VecSxp},d::Associative)
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
function sexp(::Type{VecSxp}, a::AbstractArray)
    ra = protect(allocArray(VecSxp, size(a)...))
    try
        for i in 1:length(a)
            ra[i] = a[i]
        end
    finally
        unprotect(1)
    end
    ra
end

# Function

# check src/callback.jl for `sexp(::ClosSxp, ::Function)`


# R formula objects
# TODO: never used
# function sexp(::Type{ExprSxp}, f::Formula)
#     s = protect(rlang_p(:~,rlang_formula(f.lhs),rlang_formula(f.rhs)))
#     try
#         setattrib!(s,Const.ClassSymbol,sexp("formula"))
#         setattrib!(s,".Environment",Const.GlobalEnv)
#     finally
#         unprotect(1)
#     end
#     s
# end
