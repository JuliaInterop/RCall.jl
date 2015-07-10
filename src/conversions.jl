
# Fallbacks
@doc """
`rcopy(T,p)` converts a pointer `p` to a SxpRec object to a native Julia object of type T.

`rcopy(p)` performs a default conversion.
""" ->
rcopy{S<:SxpRec}(::Type{Any},x::Ptr{S}) = rcopy(x)

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
`sexp(S,x)` converts a Julia object `x` to a pointer to a SxpRec object of type `S`.

`sexp(x)` performs a default conversion.
""" ->
sexp(::Type{SxpRecHead},x) = sexp(x)

# used in vector indexing
sexp(::Type{Cint},x) = convert(Cint,x)
sexp(::Type{Float64},x) = convert(Float64,x)
sexp(::Type{Complex128},x) = convert(Complex128,x)



# NilSxpRec
sexp(::Type{Nothing}) = rNilValue
rcopy(::Ptr{NilSxpRec}) = nothing

# SymSxpRec
@doc "Create a `SymSxpRec` from a `Symbol`"->
sexp(::Type{SymSxpRec}, s::String) = ccall((:Rf_install,libR),Ptr{SymSxpRec},(Ptr{UInt8},),bytestring(s))
sexp(::Type{SymSxpRec}, s::Symbol) = sexp(SymSxpRec,string(s))

@doc "Generic function for constructing SxpRecs from Julia objects."->
sexp(s::Symbol) = sexp(SymSxpRec,s)

rcopy(::Type{Symbol},ss::SymSxpRec) = symbol(rcopy(String,ss))
rcopy(::Type{String},ss::SymSxpRec) = rcopy(String,ss.name)
rcopy{T<:Union(Symbol,String)}(::Type{T},s::Ptr{SymSxpRec}) =
    rcopy(T,unsafe_load(s))
#Base.symbol(s::Ptr{SymSxpRec}) = rcopy(Symbol,s)


@doc """
`rcopy` copies the contents of an R object into a corresponding canonical Julia type.
""" ->
rcopy(s::Ptr{SymSxpRec}) = rcopy(Symbol,s)



# CharSxpRec
@doc """
Create a `CharSxpRec` from a String.
"""->
sexp(::Type{CharSxpRec},st::ASCIIString) =
    ccall((:Rf_mkCharLen,libR),Ptr{CharSxpRec},(Ptr{UInt8},Cint),st,sizeof(st))
sexp(::Type{CharSxpRec},st::UTF8String) =
    ccall((:Rf_mkCharLenCE,libR),Ptr{CharSxpRec},(Ptr{UInt8},Cint,Cint),st,sizeof(st),1)

sexp(::Type{CharSxpRec},st::String) = sexp(CharSxpRec,bytestring(st))
sexp(::Type{CharSxpRec},sym::Symbol) = sexp(CharSxpRec,string(sym))


rcopy{T<:String}(::Type{T},s::Ptr{CharSxpRec}) = convert(T, bytestring(unsafe_vec(s)))
rcopy(::Type{Symbol},s::Ptr{CharSxpRec}) = symbol(rcopy(String,s))
rcopy(s::Ptr{CharSxpRec}) = rcopy(String,s)



@doc """
Determines the encoding of the CharSxpRec. This is determined by the 'gp' part of the sxpinfo (this is the middle 16 bits).
 * 0x00_0002_00 (bit 1): set of bytes (no known encoding)
 * 0x00_0004_00 (bit 2): Latin-1
 * 0x00_0008_00 (bit 3): UTF-8
 * 0x00_4000_00 (bit 6): ASCII
"""->
function encoding(s::CharSxpRec)
    if s.head.info & 0x00_0040_00 != 0
        return ASCIIString
    elseif s.info & 0x00_0008_00 != 0
        return UTF8String
    else
        error("Unknown string type")
    end
end
encoding(s::Ptr{CharSxpRec}) = encoding(unsafe_load(s))

@doc "Create a `StrSxpRec` from a `String`"->
sexp(::Type{StrSxpRec}, s::Ptr{CharSxpRec}) =
    ccall((:Rf_ScalarString,libR),Ptr{StrSxpRec},(Ptr{CharSxpRec},),s)

sexp(::Type{StrSxpRec},st::String) = sexp(StrSxpRec,sexp(CharSxpRec,st))
sexp(st::String) = sexp(StrSxpRec,st)



# general vectors
function sexp{S<:VectorListSxpRec}(::Type{S}, a::AbstractArray)
    ra = protect(allocArray(S, size(a)...))
    for i in 1:length(a)
        ra[i] = a[i]
    end
    unprotect(1)
    ra
end
sexp(a::AbstractArray) = sexp(VecSxpRec,a)

function rcopy{T,S<:VectorSxpRec}(::Type{Array{T}}, s::Ptr{S})
    v = T[rcopy(e) for e in s]
    reshape(v,size(s))
end
function rcopy{S<:VectorSxpRec}(s::Ptr{S})
    v = [rcopy(e) for e in s]
    reshape(v,size(s))
end


# StrSxpRec
sexp{S<:String}(a::AbstractArray{S}) = sexp(StrSxpRec,a)
rcopy{T<:String}(::Type{T},s::Ptr{StrSxpRec}) = convert(T,s[1])


# LglSxpRec, IntSxpRec, RealSxpRec, CplxSxpRec
for (J,Jc,rsnm,S) in ((:Bool, :Cint, "Logical", :LglSxpRec),
                      (:Integer, :Cint, "Integer", :IntSxpRec),
                      (:Real, :Float64, "Real", :RealSxpRec),
                      (:Complex, :Complex128, "Complex", :CplxSxpRec))
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

# Handle LglSxpRec seperately
sexp(::Type{LglSxpRec},v::Union(Bool,Cint)) =
    ccall((:Rf_ScalarLogical,libR),Ptr{LglSxpRec},(Cint,),v)
function sexp{T<:Union(Bool,Cint)}(::Type{LglSxpRec}, a::AbstractArray{T})
    ra = allocArray(LglSxpRec, size(a)...)
    copy!(unsafe_vec(ra),a)
    ra
end
sexp(v::Bool) = sexp(LglSxpRec,v)
sexp(a::AbstractArray{Bool}) = sexp(LglSxpRec,a)

rcopy(::Type{Cint},s::Ptr{LglSxpRec}) = convert(T,s[1])
rcopy(::Type{Bool},s::Ptr{LglSxpRec}) = convert(T,s[1]!=0)

function rcopy(::Type{Array{Cint}},s::Ptr{LglSxpRec})
    a = Array(Cint,size(s)...)
    copy!(a,unsafe_vec(s))
    a
end
function rcopy(::Type{Array{Bool}},s::Ptr{LglSxpRec})
    a = Array(Bool,size(s)...)
    v = unsafe_vec(s)
    for i = 1:length(a)
        a[i] = v[i] != 0
    end
    a
end
function rcopy(::Type{BitArray},s::Ptr{LglSxpRec})
    a = BitArray(size(s)...)
    v = unsafe_vec(s)
    for i = 1:length(a)
        a[i] = v[i] != 0
    end
    a
end
rcopy(s::Ptr{LglSxpRec}) = rcopy(BitArray,s)


# Associative types

# R does not have a native dictionary type, but named vectors/lists are often
# used to this effect.
function sexp{S<:VectorSxpRec}(::Type{S},d::Associative)
    n = length(d)
    ks = protect(allocVector(StrSxpRec,n))
    vs = protect(allocVector(VecSxpRec,n))

    for (i,(k,v)) in enumerate(d)
        ks[i] = string(k)
        vs[i] = v
    end

    setNames!(vs,ks)
    unprotect(2)
    vs
end
sexp{K,V<:String}(d::Associative{K,V}) = sexp(StrSxpRec,d)
sexp(d::Associative) = sexp(VecSxpRec,d)


function rcopy{A<:Associative,S<:VectorSxpRec}(::Type{A}, s::Ptr{S})
    a = A()
    K,V = eltype(a)
    for (k,v) in zip(getNames(s),s)
        a[rcopy(K,k)] = rcopy(V,v)
    end
    a
end

function rcopy{A<:Associative,S<:PairListSxpRec}(::Type{A}, s::Ptr{S})
    protect(s)
    a = A()
    K,V = eltype(a)
    for (k,v) in s
        a[rcopy(K,k)] = rcopy(V,v)
    end
    unprotect(1)
    a
end

