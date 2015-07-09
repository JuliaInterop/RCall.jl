
# Fallbacks
@doc """
`rcopy(T,p)` converts a pointer `p` to a SEXPREC object to a native Julia object of type T.

`rcopy(p)` performs a default conversion.
""" ->
rcopy{S<:SEXPREC}(::Type{Any},x::Ptr{S}) = rcopy(x)

# used in vector indexing
for T in [:Cint, :Float64, :Complex128]
    @eval begin
        rcopy(x::$T) = x
        rcopy(::Type{$T}, x::$T) = x
    end
end

rcopy(r::RObject) = rcopy(r.p)
rcopy{T}(::Type{T},r::RObject) = rcopy(T,r.p)


@doc """
`sexp(S,x)` converts a Julia object `x` to a pointer to a SEXPREC object of type `S`.

`sexp(x)` performs a default conversion.
""" ->
sexp(::Type{SxpHead},x) = sexp(x)

# used in vector indexing
sexp(::Type{Cint},x) = convert(Cint,x)
sexp(::Type{Float64},x) = convert(Float64,x)
sexp(::Type{Complex128},x) = convert(Complex128,x)



# NilSxp
sexp(::Type{Nothing}) = rNilValue
rcopy(::Ptr{NilSxp}) = nothing

# SymSxp
@doc "Create a `SymSxp` from a `Symbol`"->
sexp(::Type{SymSxp}, s::String) = ccall((:Rf_install,libR),Ptr{SymSxp},(Ptr{UInt8},),bytestring(s))
sexp(::Type{SymSxp}, s::Symbol) = sexp(SymSxp,string(s))

@doc "Generic function for constructing SEXPRECs from Julia objects."->
sexp(s::Symbol) = sexp(SymSxp,s)

rcopy(::Type{Symbol},ss::SymSxp) = symbol(rcopy(String,ss))
rcopy(::Type{String},ss::SymSxp) = rcopy(String,ss.name)
rcopy{T<:Union(Symbol,String)}(::Type{T},s::Ptr{SymSxp}) =
    rcopy(T,unsafe_load(s))
#Base.symbol(s::Ptr{SymSxp}) = rcopy(Symbol,s)


@doc """
`rcopy` copies the contents of an R object into a corresponding canonical Julia type.
""" ->
rcopy(s::Ptr{SymSxp}) = rcopy(Symbol,s)



# CharSxp
@doc """
Create a `CharSxp` from a String.
"""->
sexp(::Type{CharSxp},st::ASCIIString) =
    ccall((:Rf_mkCharLen,libR),Ptr{CharSxp},(Ptr{UInt8},Cint),st,sizeof(st))
sexp(::Type{CharSxp},st::UTF8String) =
    ccall((:Rf_mkCharLenCE,libR),Ptr{CharSxp},(Ptr{UInt8},Cint,Cint),st,sizeof(st),1)

sexp(::Type{CharSxp},st::String) = sexp(CharSxp,bytestring(st))
sexp(::Type{CharSxp},sym::Symbol) = sexp(CharSxp,string(sym))


rcopy{T<:String}(::Type{T},s::Ptr{CharSxp}) = convert(T, bytestring(unsafe_vec(s)))
rcopy(::Type{Symbol},s::Ptr{CharSxp}) = symbol(rcopy(String,s))
rcopy(s::Ptr{CharSxp}) = rcopy(String,s)



@doc """
Determines the encoding of the CharSxp. This is determined by the 'gp' part of the sxpinfo (this is the middle 16 bits).
 * 0x00_0002_00 (bit 1): set of bytes (no known encoding)
 * 0x00_0004_00 (bit 2): Latin-1
 * 0x00_0008_00 (bit 3): UTF-8
 * 0x00_4000_00 (bit 6): ASCII
"""->
function encoding(s::CharSxp)
    if s.head.info & 0x00_0040_00 != 0
        return ASCIIString
    elseif s.info & 0x00_0008_00 != 0
        return UTF8String
    else
        error("Unknown string type")
    end
end
encoding(s::Ptr{CharSxp}) = encoding(unsafe_load(s))

@doc "Create a `StrSxp` from a `String`"->
sexp(::Type{StrSxp}, s::Ptr{CharSxp}) =
    ccall((:Rf_ScalarString,libR),Ptr{StrSxp},(Ptr{CharSxp},),s)

sexp(::Type{StrSxp},st::String) = sexp(StrSxp,sexp(CharSxp,st))
sexp(st::String) = sexp(StrSxp,st)



# general vectors
function sexp{S<:VectorList}(::Type{S}, a::AbstractArray)
    ra = protect(allocArray(S, size(a)...))
    for i in 1:length(a)
        ra[i] = a[i]
    end
    unprotect(1)
    ra
end
sexp(a::AbstractArray) = sexp(VecSxp,a)

function rcopy{T,S<:RVector}(::Type{Array{T}}, s::Ptr{S})
    v = T[rcopy(e) for e in s]
    reshape(v,size(s))
end
function rcopy{S<:RVector}(s::Ptr{S})
    v = [rcopy(e) for e in s]
    reshape(v,size(s))
end


# StrSxp
sexp{S<:String}(a::AbstractArray{S}) = sexp(StrSxp,a)
rcopy{T<:String}(::Type{T},s::Ptr{StrSxp}) = convert(T,s[1])


# LglSxp, IntSxp, RealSxp, CplxSxp
for (J,Jc,rsnm,S) in ((:(Union(Bool,Cint)), :Cint, "Logical", :LglSxp),
                      (:Integer, :Cint, "Integer", :IntSxp),
                      (:Real, :Float64, "Real", :RealSxp),
                      (:Complex, :Complex128, "Complex", :CplxSxp))
    @eval begin
        sexp(::Type{$S},v::$J) =
            ccall(($(string("Rf_Scalar",rsnm)),libR),Ptr{$S},($Jc,),v)
        function sexp{T<:$J}(::Type{$S}, a::AbstractArray{T})
            ra = allocArray($S, size(a)...)
            copy!(unsafe_vec(ra),a)
            ra
        end
        sexp(v::$J) = sexp($S,v)
        sexp{T<:$J}(a::AbstractArray{T}) = sexp($S,a)

        rcopy{T<:$J}(::Type{T},s::Ptr{$S}) = convert(T,s[1])
        function rcopy{T<:$J}(::Type{Array{T}},s::Ptr{$S})
            a = Array(T,size(s)...)
            copy!(a,unsafe_vec(s))
            a
        end
    end
end

function rcopy(::Type{BitArray},s::Ptr{LglSxp})
    a = BitArray(size(s)...)
    copy!(a,unsafe_vec(s))
    a
end
rcopy(s::Ptr{LglSxp}) = rcopy(BitArray,s)


# Associative types

# R does not have a native dictionary type, but named vectors/lists are often
# used to this effect.
function sexp{S<:RVector}(::Type{S},d::Associative)
    n = length(d)
    ks = protect(allocVector(StrSxp,n))
    vs = protect(allocVector(VecSxp,n))

    for (i,(k,v)) in enumerate(d)
        ks[i] = string(k)
        vs[i] = v
    end

    setNames!(vs,ks)
    unprotect(2)
    vs
end
sexp{K,V<:String}(d::Associative{K,V}) = sexp(StrSxp,d)
sexp(d::Associative) = sexp(VecSxp,d)


function rcopy{A<:Associative,S<:RVector}(::Type{A}, s::Ptr{S})
    a = A()
    K,V = eltype(a)
    for (k,v) in zip(getNames(s),s)
        a[rcopy(K,k)] = rcopy(V,v)
    end
    a
end

function rcopy{A<:Associative,S<:PairList}(::Type{A}, s::Ptr{S})
    protect(s)
    a = A()
    K,V = eltype(a)
    for (k,v) in s
        a[rcopy(K,k)] = rcopy(V,v)
    end
    unprotect(1)
    a
end

