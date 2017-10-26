# conversion methods for DataArrays, PooledDataArrays

function rcopy{T,S<:VectorSxp}(::Type{DataArray{T}}, s::Ptr{S})
    DataArray(rcopy(Array{T},s), isna(s))
end
function rcopy{S<:VectorSxp}(::Type{DataArray}, s::Ptr{S})
    DataArray(rcopy(Array,s), isna(s))
end

function rcopy(::Type{DataArray}, s::Ptr{IntSxp})
    isFactor(s) && error("s is an R factor")
    DataArray(rcopy(Array,s), isna(s))
end
function rcopy(::Type{PooledDataArray}, s::Ptr{IntSxp})
    isFactor(s) || error("s is not an R factor")
    refs = DataArrays.RefArray([isNA(x) ? zero(Int32) : x for x in s])
    DataArrays.compact(PooledDataArray(refs, rcopy(Array, getattrib(s,Const.LevelsSymbol))))
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


## PooledDataArray to sexp conversion.
function sexp{T<:AbstractString,R<:Integer}(::Type{IntSxp}, v::PooledDataArray{T,R})
    rv = protect(sexp(IntSxp, v.refs))
    try
        for (i,r) = enumerate(v.refs)
            if r == 0
                rv[i] = naeltype(IntSxp)
            end
        end
    finally
        unprotect(1)
    end
    setattrib!(rv, Const.LevelsSymbol, sexp(v.pool))
    setattrib!(rv, Const.ClassSymbol, sexp("factor"))
    rv
end
