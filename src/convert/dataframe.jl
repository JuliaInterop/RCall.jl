# conversion methods for DataArrays, PooledDataArrays and DataFrames

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
    DataArrays.compact(PooledDataArray(refs,rcopy(getattrib(s,Const.LevelsSymbol))))
end

function rcopy(::Type{DataFrame}, s::Ptr{VecSxp})
    isFrame(s) || error("s is not a R data frame")
    DataFrame(Any[rcopy(c) for c in s], rcopy(Array{Symbol},getnames(s)))
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

# R formula objects
function sexp(::Type{ExprSxp}, f::Formula)
    s = protect(rlang_p(:~,rlang_formula(f.lhs),rlang_formula(f.rhs)))
    try
        setattrib!(s,Const.ClassSymbol,sexp("formula"))
        setattrib!(s,".Environment",Const.GlobalEnv)
    finally
        unprotect(1)
    end
    s
end

# formula
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
