# conversion methods for NullableArrays

function rcopy(::Type{Nullable{T}}, s::Ptr{S}) where {T,S<:Sxp}
    length(s) == 1 || error("length of s must be 1.")
    if isNA(s[1])
        Nullable{T}()
    else
        Nullable{T}(rcopy(T, s))
    end
end


# Default behaviors of copying R vectors to nullablearrays

for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp)
    @eval begin
        function rcopy(::Type{Nullable}, s::Ptr{$S})
            protect(s)
            try
                class = rcopy(Symbol, getclass(s, true))
                return rcopy(Nullable{eltype(RClass{class}, s)}, s)
            finally
                unprotect(1)
            end
        end
        function rcopy(::Type{NullableVector},s::Ptr{$S})
            protect(s)
            try
                class = rcopy(Symbol, getclass(s, true))
                return rcopy(NullableVector{eltype(RClass{class}, s)}, s)
            finally
                unprotect(1)
            end
        end
        function rcopy(::Type{NullableArray},s::Ptr{$S})
            protect(s)
            try
                class = rcopy(Symbol, getclass(s, true))
                return rcopy(NullableArray{eltype(RClass{class}, s)}, s)
            finally
                unprotect(1)
            end
        end
    end
end

function rcopy(::Type{NullableArray{T}}, s::Ptr{S}) where {T,S<:VectorSxp}
    NullableArray(rcopy(Array{T},s), isna(s))
end

function rcopy(::Type{NullableVector{T}}, s::Ptr{S}) where {T, S<:VectorSxp}
    NullableArray(rcopy(Vector{T},s), isna(s))
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
