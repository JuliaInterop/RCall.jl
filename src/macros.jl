"""
    @rput(args...)

Copy variable(s) from Julia to R using the same name.
"""
macro rput(args...)
    blk = Expr(:block)
    for a in args
        if isa(a, Symbol)
            v = a
            push!(blk.args, :(Const.GlobalEnv[$(QuoteNode(v))] = $(esc(v))))
        elseif isa(a, Expr) && a.head == :(::)
            v = a.args[1]
            S = a.args[2]
            push!(blk.args, :(Const.GlobalEnv[$(QuoteNode(v))] = robject($S, $(esc(v)))))
        else
            error("Incorrect usage of @rput")
        end
    end
    blk
end

"""
    @rget(args...)

Copy variable(s) from R to Julia using the same name.
"""
macro rget(args...)
    blk = Expr(:block)
    for a in args
        if isa(a, Symbol)
            v = a
            push!(blk.args, :($(esc(v)) = rcopy(Const.GlobalEnv[$(QuoteNode(v))])))
        elseif isa(a, Expr) && a.head == :(::)
            v = a.args[1]
            T = a.args[2]
            push!(blk.args, :($(esc(v)) = rcopy($(esc(T)),Const.GlobalEnv[$(QuoteNode(v))])))
        else
            error("Incorrect usage of @rget")
        end
    end
    blk
end

"""
    R"..."

An inline R expression, the result of which is evaluated and returned as an `RObject`.

It supports substitution of Julia variables and expressions via prefix with `\$` whenever
not valid R syntax (i.e. when not immediately following another completed R expression):

    R"glm(Sepal.Length ~ Sepal.Width, data=\$iris)"

It is also possible to pass Julia expressions:

    R"plot($(x -> exp(x).*sin(x)))"

All such Julia expressions are evaluated once, before the R expression is evaluated.

The expression does not support assigning to Julia variables, so the only way to retrieve
values from R is via the return value.
"""
macro R_str(script)
    script, symdict = render(script)

    if length(symdict) > 0
        return quote
            $(prepare_inline_julia_code(symdict, true))
            reval($script, globalEnv)
        end
    else
        return quote
            reval($script, globalEnv)
        end
    end
end
