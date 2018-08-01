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
        cargs = []
        for (t, s) in pairs(args)
            if isNull(t)
                push!(cargs, rcopy_formula(s))
            else
                push!(cargs, Expr(:(=), rcopy_formula(t), rcopy_formula(s)))
            end
        end
        f = Expr(:call, op, cargs...)
    end
    # unwind these opeators
    if op in (:+, :*, :&) && isa(f.args[2], Expr) && f.args[2].args[1] == op
        f = Expr(:call, op, f.args[2].args[2:end]..., f.args[3])
    end
    f
end

function rcopy(::Type{Formula}, l::Ptr{LangSxp})
    ex_orig = rcopy(Expr, l)
    ex = parse!(copy(ex_orig))
    lhs, rhs = ex.args[2:3]
    Formula(ex_orig, ex, lhs, rhs)
end


# julia Formula to R formula

# formula
function sexp_formula(e::Expr)
    e.head == :call || error("invalid formula object")
    op = e.args[1]
    if op == :&
        op = :(:)
    end
    if length(e.args) > 3 && op in (:+, :*, :(:))
        rlang_p(op, sexp_formula(Expr(e.head, e.args[1:end-1]...)), sexp_formula(e.args[end]))
    else
        rlang_p(op, map(sexp_formula, e.args[2:end])...)
    end
end
sexp_formula(e::Symbol) = sexp(SymSxp, e)
sexp_formula(n::Integer) = sexp(RClass{:numeric}, Float64(n))
sexp_formula(n::Number) = sexp(n)


# R formula objects
function sexp(::Type{RClass{:formula}}, f::Formula)
    s = protect(sexp_formula(f.ex_orig == :() ? f.ex : f.ex_orig))
    try
        setattrib!(s, Const.ClassSymbol, "formula")
        setattrib!(s, ".Environment", Const.GlobalEnv)
    finally
        unprotect(1)
    end
    s
end
