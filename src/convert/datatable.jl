# conversion methods for NullableArrays, CategoricalArrays and DataTables

# DataTable
function rcopy(::Type{T}, s::Ptr{VecSxp}; sanitize::Bool=true) where T<:AbstractDataTable
    isFrame(s) || error("s is not an R data frame")
    vnames = rcopy(Vector{Symbol},getnames(s))
    if sanitize
        vnames = [Symbol(replace(string(v), '.', '_')) for v in vnames]
    end
    DataTable(
        Any[isFactor(c)? rcopy(NullableCategoricalArray, c) : rcopy(NullableArray, c) for c in s],
        vnames)
end


# DataTable
function sexp(::Type{VecSxp}, d::AbstractDataTable)
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
