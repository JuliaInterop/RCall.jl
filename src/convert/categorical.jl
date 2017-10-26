function rcopy(::Type{CategoricalArray}, s::Ptr{IntSxp})
    isFactor(s) || error("s is not an R factor")
    refs = UInt32[isNA(x) ? zero(UInt32) : UInt32(x) for x in s]
    levels = rcopy(Array{String}, getattrib(s,Const.LevelsSymbol))
    pool = CategoricalPool(levels, isOrdered(s))
    if anyna(s)
        CategoricalArray{Union{String, Null}, 1, UInt32}(refs, pool)
    else
        CategoricalArray{String, 1, UInt32}(refs, pool)
    end
end

function sexp(::Type{IntSxp}, v::CategoricalArray)
    rv = protect(sexp(IntSxp, v.refs))
    try
        for (i,ref) = enumerate(v.refs)
            if ref == 0
                rv[i] = naeltype(IntSxp)
            end
        end
        # due to a bug of CategoricalArrays, we use index(v.pool) instead of index(v)
        setattrib!(rv, Const.LevelsSymbol, sexp(CategoricalArrays.index(v.pool)))
        setattrib!(rv, Const.ClassSymbol, sexp("factor"))
        if CategoricalArrays.isordered(v)
            rv = rcall(:ordered, rv, CategoricalArrays.levels(v))
        end
    finally
        unprotect(1)
    end
    rv
end
