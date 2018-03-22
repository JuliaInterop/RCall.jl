# R formula to julia Formula

# a special wrapper for rcopy specialized for formulas
function rcopy_formula(s::Ptr{S}) where S<:Sxp
    r = rcopy(s)
    if isa(r, Number) && isinteger(r)
        Int(r)
    else
        r
    end
end

function rcopy(::Type{Expr}, l::Ptr{LangSxp})
    op = rcopy(Symbol, l[1])
    if op == :(:)
        op = :&
    end
    args = cdr(l)
    if op == Symbol("(")
        f = rcopy(Expr, l[2])
    else
        f = Expr(:call, op, [rcopy_formula(s) for s in args]...)
    end
    # unwind these opeators
    if op in (:+, :*, :&) && isa(f.args[2], Expr) && f.args[2].args[1] == op
        f = Expr(:call, op, f.args[2].args[2:end]..., f.args[3])
    end
    f
end

function rcopy(::Type{Formula}, l::Ptr{LangSxp})
    Formula(rcopy(l[2]), rcopy(l[3]))
end


# julia Formula to R formula

# formula
function rlang_formula(e::Expr)
    e.head == :call || error("invalid formula object")
    op = e.args[1]
    if op == :&
        op = :(:)
    end
    if length(e.args) > 3 && op in (:+, :*, :(:))
        rlang_p(op, rlang_formula(Expr(e.head, e.args[1:end-1]...)), rlang_formula(e.args[end]))
    else
        rlang_p(op, map(rlang_formula, e.args[2:end])...)
    end
end
rlang_formula(e::Symbol) = e
rlang_formula(n::Number) = n

# R formula objects
function sexp(::Type{LangSxp}, f::Formula)
    s = protect(rlang_p(:~, rlang_formula(f.lhs),rlang_formula(f.rhs)))
    try
        setattrib!(s, Const.ClassSymbol, sexp("formula"))
        setattrib!(s, ".Environment", Const.GlobalEnv)
    finally
        unprotect(1)
    end
    s
end
