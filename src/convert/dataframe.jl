# conversion methods for DataFrames

function rcopy(::Type{T}, s::Ptr{VecSxp};
               normalizenames::Bool=true, 
               sanitize::Union{Bool,Nothing}=nothing) where T<:AbstractDataFrame
    if sanitize !== nothing
        Base.depwarn("The `sanitize` keyword argument is deprecated. Use `normalizenames` instead.", :rcopy)
        normalizenames = sanitize
    end
    isFrame(s) || error("s is not an R data frame")
    vnames = rcopy(Array{Symbol},getnames(s))
    if normalizenames
        vnames = [Symbol(replace(string(v), '.' => '_')) for v in vnames]
    end
    DataFrame([vec(rcopy(AbstractArray, c)) for c in s], vnames)
end

## DataFrame to sexp conversion.
function sexp(::Type{RClass{:list}}, d::AbstractDataFrame)
    nr,nc = size(d)
    nv = names(d)
    rd = protect(allocArray(VecSxp, nc))
    try
        for i in 1:nc
            rd[i] = sexp(d[!, nv[i]])
        end
        setattrib!(rd,Const.NamesSymbol, [string(n) for n in nv])
        setattrib!(rd,Const.ClassSymbol, "data.frame")
        setattrib!(rd,Const.RowNamesSymbol, 1:nr)
    finally
        unprotect(1)
    end
    rd
end
