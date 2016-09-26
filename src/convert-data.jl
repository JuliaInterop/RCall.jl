# conversion methods for NullableArrays, CategoricalArrays and DataFrames

function rcopy{T,S<:VectorSxp}(::Type{NullableArray{T}}, s::Ptr{S})
    NullableArray(rcopy(Array{T},s), isna(s))
end
function rcopy{S<:VectorSxp}(::Type{NullableArray}, s::Ptr{S})
    NullableArray(rcopy(Array,s), isna(s))
end

function rcopy(::Type{NullableArray}, s::Ptr{IntSxp})
    isFactor(s) && error("$s is a R factor")
    NullableArray(rcopy(Array,s), isna(s))
end
function rcopy(::Type{NullableCategoricalArray}, s::Ptr{IntSxp})
    isFactor(s) || error("$s is not a R factor")
    refs = UInt32[isna(x) ? zero(UInt32) : UInt32(x) for x in s]
    pool = CategoricalPool(rcopy(getattrib(s,Const.LevelsSymbol)))
    NullableCategoricalArray(refs, pool)
end

function rcopy(::Type{DataFrame}, s::Ptr{VecSxp})
    isFrame(s) || error("s is not a R data frame")
    DataFrame(Any[isFactor(c)? rcopy(NullableCategoricalArray, c) : rcopy(NullableArray, c) for c in s],
              rcopy(Array{Symbol},getnames(s)))
end


## NullableArray to sexp conversion.
function sexp(v::NullableArray)
    rv = protect(sexp(v.values))
    try
        for (i,isna) = enumerate(v.isnull)
            if isna
                rv[i] = naeltype(eltype(rv))
            end
        end
    finally
        unprotect(1)
    end
    rv
end

## NullableCategoricalArray to sexp conversion.
function sexp{T<:Compat.String,N,R<:Integer}(v::NullableCategoricalArray{T,N,R})
    rv = sexp(v.refs)
    setattrib!(rv, Const.LevelsSymbol, sexp(v.pool.levels))
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
