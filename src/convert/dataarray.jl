# conversion methods for DataArrays

function rcopy(::Type{DataArray{T}}, s::Ptr{S}) where {T, S<:VectorSxp}
    DataArray(rcopy(Array{T},s), isna(s))
end

function rcopy(::Type{DataArray{T}}, s::Ptr{IntSxp}) where T
    isFactor(s) && error("s is an R factor")
    DataArray(rcopy(Array{T},s), isna(s))
end

function rcopy(::Type{DataVector{T}}, s::Ptr{S}) where {T, S<:VectorSxp}
    DataArray(rcopy(Vector{T},s), isna(s))
end

function rcopy(::Type{DataVector{T}}, s::Ptr{IntSxp}) where T
    isFactor(s) && error("s is an R factor")
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
