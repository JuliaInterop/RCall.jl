# conversion methods for DataArrays, PooledDataArrays and DataFrames

## DataFrame to sexp conversion.
function sexp(d::AbstractDataFrame)
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
