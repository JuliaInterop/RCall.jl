# conversion methods for DataFrames

function rcopy(::Type{T}, s::Ptr{VecSxp}; sanitize::Bool=true) where T<:AbstractDataFrame
    isFrame(s) || error("s is not an R data frame")
    vnames = rcopy(Array{Symbol},getnames(s))
    if sanitize
        vnames = [Symbol(replace(string(v), '.', '_')) for v in vnames]
    end
    DataFrame([rcopy(c) for c in s], vnames)
end

## DataFrame to sexp conversion.
function sexp(::Type{VecSxp}, d::AbstractDataFrame)
    nr,nc = size(d)
    nv = names(d)
    rd = protect(allocArray(VecSxp, nc))
    try
        for i in 1:nc
            rd[i] = sexp(d[nv[i]])
        end
        setattrib!(rd,Const.NamesSymbol, sexp([string(n) for n in nv]))
        setattrib!(rd,Const.ClassSymbol, sexp("data.frame"))
        setattrib!(rd,Const.RowNamesSymbol, sexp(1:nr))
    finally
        unprotect(1)
    end
    rd
end
