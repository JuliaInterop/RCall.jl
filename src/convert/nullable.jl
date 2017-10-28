# conversion methods for NullableArrays

function rcopy(::Type{Nullable{T}}, s::Ptr{S}) where {T,S<:Sxp}
    length(s) == 1 || error("length of s must be 1.")
    rcopy(NullableArray{T}, s)[1]
end

function rcopy(::Type{Nullable}, s::Ptr{S}) where S<:VectorSxp
    rcopy(Nullable{eltype(S)}, s)
end

function rcopy(::Type{Nullable}, s::Ptr{S}) where S<:IntSxp
    rcopy(Nullable{Int}, s)
end

function rcopy(::Type{Nullable}, s::Ptr{S}) where S<:StrSxp
    rcopy(Nullable{String}, s)
end

function rcopy(::Type{NullableArray{T}}, s::Ptr{S}) where {T,S<:VectorSxp}
    NullableArray(rcopy(Array{T},s), isna(s))
end
function rcopy(::Type{NullableArray}, s::Ptr{S}) where S<:VectorSxp
    NullableArray(rcopy(Array,s), isna(s))
end

function rcopy(::Type{NullableArray}, s::Ptr{IntSxp})
    isFactor(s) && error("s is an R factor")
    NullableArray(rcopy(Array,s), isna(s))
end


# Nullable and NullableArray to sexp conversion.
for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp)
    @eval begin
        function sexp(::Type{$S}, x::Nullable)
            if isnull(x)
                return sexp($S, naeltype($S))
            else
                return sexp($S, x.value)
            end
        end
        function sexp(::Type{$S}, v::NullableArray)
            rv = protect(sexp($S, v.values))
            try
                for (i,isna) = enumerate(v.isnull)
                    if isna
                        rv[i] = naeltype($S)
                    end
                end
            finally
                unprotect(1)
            end
            rv
        end
    end
end
