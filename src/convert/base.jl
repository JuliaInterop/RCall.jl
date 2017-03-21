# conversion to Base Julia types

# allow `Int(R"1+1")`
rcopy{T}(::Type{T},r::RObject) = rcopy(T,r.p)
convert{T, S<:Sxp}(::Type{T}, r::RObject{S}) = rcopy(T,r.p)
convert{S<:Sxp}(::Type{RObject{S}}, r::RObject{S}) = r

# conversion between numbers which understands different NAs
function rcopy{T<:Number, R<:Number}(::Type{T}, x::R)
    if (R <: AbstractFloat && !isnan(x)) || (R == Int32 && !isna(x))
        return T(x)
    elseif R == Int32 && T <: AbstractFloat
        return T(NaN)
    elseif R <: AbstractFloat && T == Int32
        return Const.NaInt
    else
        return T(x)
    end
end

# NilSxp
rcopy{T}(::Type{T}, ::Ptr{NilSxp}) = nothing
rcopy{T<:AbstractArray}(::Type{T}, ::Ptr{NilSxp}) = T()

# SymSxp
rcopy{T<:Union{Symbol,AbstractString}}(::Type{T},s::Ptr{SymSxp}) = rcopy(T, sexp(unsafe_load(s).name))

# CharSxp
rcopy{T<:AbstractString}(::Type{T},s::CharSxpPtr) = convert(T, String(unsafe_vec(s)))
rcopy(::Type{Symbol},s::CharSxpPtr) = Symbol(rcopy(AbstractString,s))
rcopy(::Type{Int}, s::CharSxpPtr) = parse(Int, rcopy(s))

# IntSxp, RealSxp, CplxSxp, LglSxp, StrSxp, VecSxp to Array{T}
for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp, :VecSxp)
    @eval begin
        function rcopy{T}(::Type{Array{T}}, s::Ptr{$S})
            protect(s)
            v = T[rcopy(T,e) for e in s]
            ret = reshape(v,size(s))
            unprotect(1)
            ret
        end
        function rcopy{T}(::Type{Vector{T}}, s::Ptr{$S})
            protect(s)
            ret = T[rcopy(T,e) for e in s]
            unprotect(1)
            ret
        end
    end
end

# IntSxp, RealSxp, CplxSxp to their corresponding Julia types.
for (J,S) in ((:Integer,:IntSxp),
                 (:AbstractFloat, :RealSxp),
                 (:Complex, :CplxSxp))
    @eval begin
        rcopy{T<:$J}(::Type{T},s::Ptr{$S}) = convert(T,s[1])
        function rcopy{T<:$J}(::Type{Vector{T}},s::Ptr{$S})
            a = Array{T}(length(s))
            copy!(a,unsafe_vec(s))
            a
        end
        function rcopy{T<:$J}(::Type{Array{T}},s::Ptr{$S})
            a = Array{T}(size(s)...)
            copy!(a,unsafe_vec(s))
            a
        end
        rcopy(::Type{Vector},s::Ptr{$S}) = rcopy(Vector{eltype($S)},s)
        rcopy(::Type{Array},s::Ptr{$S}) = rcopy(Array{eltype($S)},s)
    end
end

# LglSxp
rcopy(::Type{Cint},s::Ptr{LglSxp}) = convert(Cint,s[1])
rcopy(::Type{Bool},s::Ptr{LglSxp}) = s[1]!=0

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
rcopy(::Type{Array},s::Ptr{LglSxp}) = rcopy(Array{Bool},s)
rcopy(::Type{Vector},s::Ptr{LglSxp}) = rcopy(Vector{Bool},s)
function rcopy(::Type{BitArray},s::Ptr{LglSxp})
    a = BitArray(size(s)...)
    v = unsafe_vec(s)
    for i = 1:length(a)
        a[i] = v[i] != 0
    end
    a
end

# StrSxp
rcopy(::Type{Vector}, s::StrSxpPtr) = rcopy(Vector{String}, s)
rcopy(::Type{Array}, s::StrSxpPtr) = rcopy(Array{String}, s)
rcopy(::Type{Symbol}, s::StrSxpPtr) = rcopy(Symbol,s[1])
rcopy{T<:AbstractString}(::Type{T},s::StrSxpPtr) = rcopy(T,s[1])

# VecSxp
rcopy(::Type{Array}, s::Ptr{VecSxp}) = rcopy(Array{Any}, s)
rcopy(::Type{Vector}, s::Ptr{VecSxp}) = rcopy(Vector{Any}, s)
function rcopy{A<:Associative}(::Type{A}, s::Ptr{VecSxp})
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
function rcopy{S<:FunctionSxp}(::Type{Function}, s::Ptr{S})
    (args...) -> rcopy(rcall_p(s,args...))
end
function rcopy{S<:FunctionSxp}(::Type{Function}, r::RObject{S})
    (args...) -> rcopy(rcall_p(r,args...))
end


# conversion from Base Julia types

# nothing
sexp{S<:Sxp}(::Type{S}, ::Void) = sexp(Const.NilValue)

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
        function sexp{T<:$J}(::Type{$S}, a::AbstractArray{T})
            ra = allocArray($S, size(a)...)
            copy!(unsafe_vec(ra),a)
            ra
        end
    end
end

# bool and boolean array, handle seperately
sexp(::Type{LglSxp},v::Union{Bool,Cint}) =
    ccall((:Rf_ScalarLogical,libR),Ptr{LglSxp},(Cint,),v)
function sexp{T<:Union{Bool,Cint}}(::Type{LglSxp}, a::AbstractArray{T})
    ra = allocArray(LglSxp, size(a)...)
    copy!(unsafe_vec(ra),a)
    ra
end

# String
sexp(::Type{SymSxp}, s::AbstractString) = ccall((:Rf_install, libR), Ptr{SymSxp}, (Ptr{UInt8},), s)
sexp(::Type{CharSxp}, st::String) =
    ccall((:Rf_mkCharLenCE, libR), CharSxpPtr,
          (Ptr{UInt8}, Cint, Cint), st, sizeof(st), isascii(st) ? 0 : 1)
sexp(::Type{CharSxp}, st::AbstractString) = sexp(CharSxp, String(st))
sexp(::Type{StrSxp}, s::CharSxpPtr) = ccall((:Rf_ScalarString,libR),Ptr{StrSxp},(CharSxpPtr,),s)
sexp(::Type{StrSxp},st::AbstractString) = sexp(StrSxp,sexp(CharSxp,st))
function sexp{T<:AbstractString}(::Type{StrSxp}, a::AbstractArray{T})
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
"""
Wrap a callable Julia object `f` an a R `ClosSxpPtr`.

Constructs the following R code

    function(...) .External(juliaCallback, fExPtr, ...)

"""
function sexp(::Type{ClosSxp}, f)
    fptr = protect(sexp(ExtPtrSxp,f))
    body = protect(rlang_p(Symbol(".External"),
                           juliaCallback,
                           fptr,
                           Const.DotsSymbol))
    local clos
    try
        lang = rlang_p(:function, sexp_arglist_dots(), body)
        clos = reval_p(lang)
    finally
        unprotect(2)
    end
    clos
end
