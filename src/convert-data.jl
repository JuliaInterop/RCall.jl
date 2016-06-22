# conversion methods for DataArrays and DataFrames

function rcopy{T,S<:VectorSxp}(::Type{DataArray{T}}, s::Ptr{S})
    DataArray(rcopy(Array{T},s), isna(s))
end
function rcopy{S<:VectorSxp}(::Type{DataArray}, s::Ptr{S})
    DataArray(rcopy(Array,s), isna(s))
end

function rcopy(::Type{DataArray}, s::Ptr{IntSxp})
    isFactor(s) && error("$s is a R factor")
    DataArray(rcopy(Array,s), isna(s))
end
function rcopy(::Type{PooledDataArray}, s::Ptr{IntSxp})
    isFactor(s) || error("$s is not a R factor")
    refs = DataArrays.RefArray([isna(x) ? zero(Int32) : x for x in s])
    compact(PooledDataArray(refs,rcopy(getattrib(s,Const.LevelsSymbol))))
end
rcopy{S<:VectorSxp}(::Type{AbstractDataArray}, s::Ptr{S}) = rcopy(DataArray, s)
rcopy(::Type{AbstractDataArray}, s::Ptr{IntSxp}) =
    isFactor(s) ? rcopy(PooledDataArray,s) : rcopy(DataArray,s)

function rcopy(::Type{DataFrame}, s::Ptr{VecSxp})
    isFrame(s) || error("s is not a R data frame")
    DataFrame([rcopy(AbstractDataArray, c) for c in s],
              rcopy(Array{Symbol},getnames(s)))
end


## DataArray to sexp conversion.
function sexp(v::DataArray)
    rv = protect(sexp(v.data))
    try
        for (i,isna) = enumerate(v.na)
            if isna
                rv[i] = naeltype(eltype(rv))
            end
        end
    finally
        unprotect(1)
    end
    rv
end

## PooledDataArray to sexp conversion.
function sexp{T<:Compat.String,R<:Integer}(v::PooledDataArray{T,R})
    rv = sexp(v.refs)
    setattrib!(rv, Const.LevelsSymbol, sexp(v.pool))
    setattrib!(rv, Const.ClassSymbol, sexp("factor"))
    rv
end

## DataFrame to sexp conversion.
function sexp(d::DataFrame)
    nr,nc = size(d)
    rd = protect(allocArray(VecSxp, nc))
    try
        for i in 1:nc
            rd[i] = sexp(d[d.colindex.names[i]])
        end
        setattrib!(rd,Const.NamesSymbol, sexp([string(n) for n in d.colindex.names]))
        setattrib!(rd,Const.ClassSymbol, sexp("data.frame"))
        setattrib!(rd,Const.RowNamesSymbol, sexp(1:nr))
    finally
        unprotect(1)
    end
    rd
end


# R formula objects
function sexp(f::Formula)
    s = protect(rlang_p(:~,rlang_formula(f.lhs),rlang_formula(f.rhs)))
    try
        setattrib!(s,Const.ClassSymbol,sexp("formula"))
        setattrib!(s,".Environment",Const.GlobalEnv)
    finally
        unprotect(1)
    end
    s
end

function rlang_formula(e::Expr)
    e.head == :call || error("invalid formula object")
    op = e.args[1]
    if op == :&
        op = :(:)
    end
    if length(e.args) > 3 && op in (:+,:*,:(:))
        rlang_p(op,
                rlang_formula(Expr(e.head,e.args[1:end-1]...)),
                rlang_formula(e.args[end]))
    else
        rlang_p(op,map(rlang_formula,e.args[2:end])...)
    end
end
rlang_formula(e::Symbol) = e
rlang_formula(n::Number) = n
