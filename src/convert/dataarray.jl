# conversion methods for DataArrays

# Default behaviors of copying R vectors to dataarrays

for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp)
    @eval begin
        function rcopy(::Type{DataVector},s::Ptr{$S})
            protect(s)
            try
                class = rcopy(Symbol, getclass(s, true))
                return rcopy(DataVector{eltype(RClass{class}, s)}, s)
            finally
                unprotect(1)
            end
        end
        function rcopy(::Type{DataArray},s::Ptr{$S})
            protect(s)
            try
                class = rcopy(Symbol, getclass(s, true))
                return rcopy(DataArray{eltype(RClass{class}, s)}, s)
            finally
                unprotect(1)
            end
        end
    end
end

function rcopy(::Type{DataArray{T}}, s::Ptr{S}) where {T, S<:VectorSxp}
    DataArray(rcopy(Array{T},s), isna(s))
end

function rcopy(::Type{DataVector{T}}, s::Ptr{S}) where {T, S<:VectorSxp}
    DataArray(rcopy(Vector{T},s), isna(s))
end


## DataArray to sexp conversion.
for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp)
    @eval begin
        function sexp(::Type{$S}, v::DataArray)
            rv = protect(sexp($S, v.data))
            try
                for (i,isna) = enumerate(v.na)
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
