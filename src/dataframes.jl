## Methods related to the SEXP (pointer to SxpRec type) in R


rcopy{S<:VectorSxpRec}(::Type{DataArray}, s::Ptr{S}) = DataArray(rcopy(s), isNA(s))
rcopy(::Type{DataArray}, s::Ptr{LglSxpRec}) = DataArray(rcopy(Array{Bool},s), isNA(s))

function rcopy(::Type{DataArray}, s::Ptr{IntSxpRec})
    isFactor(s) && error("$s is a R factor")
    DataArray(rcopy(s), isNA(s))
end
function rcopy(::Type{PooledDataArray}, s::Ptr{IntSxpRec})
    isFactor(s) || error("$s is not a R factor")
    refs = DataArrays.RefArray([x == rNaInt ? zero(Int32) : x for x in s])
    compact(PooledDataArray(refs,rcopy(getAttrib(s,rLevelsSymbol))))
end
rcopy{S<:VectorSxpRec}(::Type{AbstractDataArray}, s::Ptr{S}) = rcopy(DataArray, s)
rcopy(::Type{AbstractDataArray}, s::Ptr{IntSxpRec}) =
    isFactor(s) ? rcopy(PooledDataArray,s) : rcopy(DataArray,s)

function rcopy(::Type{DataFrame}, s::Ptr{VecSxpRec})
    isFrame(s) || error("s is not a R data frame")
    DataFrame([rcopy(AbstractDataArray, c) for c in s],
              rcopy(Array{Symbol},getNames(s)))
end


## DataArray to sexp conversion.
function sexp(v::DataArray)
    rv = protect(sexp(v.data))
    for (i,isna) = enumerate(v.na)
        if isna
            rv[i] = NAel(eltype(rv))
        end
    end
    unprotect(1)
    rv
end

## PooledDataArray to sexp conversion.
function sexp{T<:ByteString,R<:Integer}(v::PooledDataArray{T,R})
    rv = sexp(v.refs)
    setAttrib!(rv, rLevelsSymbol, sexp(v.pool))
    setAttrib!(rv, rClassSymbol, sexp("factor"))
    rv
end

## DataFrame to sexp conversion.
function sexp(d::DataFrame)
    nr,nc = size(d)
    rd = protect(allocArray(VecSxpRec, nc))
    for i in 1:nc
        rd[i] = sexp(d[d.colindex.names[i]])
    end
    setAttrib!(rd,rNamesSymbol, sexp([string(n) for n in d.colindex.names]))
    setAttrib!(rd,rClassSymbol, sexp("data.frame"))
    setAttrib!(rd,rRowNamesSymbol, sexp(1:nr))
    unprotect(1)
    rd
end
