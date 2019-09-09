# conversion methods for CategoricalArrays

function rcopy(::Type{CategoricalArray}, s::Ptr{IntSxp})
    isFactor(s) || error("s is not an R factor")
    refs = UInt32[isNA(x) ? zero(UInt32) : UInt32(x) for x in s]
    levels = rcopy(Array{String}, getattrib(s,Const.LevelsSymbol))
    pool = CategoricalPool(levels, isOrdered(s))
    if anyna(s)
        CategoricalArray{Union{String, Missing}, 1}(refs, pool)
    else
        CategoricalArray{String, 1}(refs, pool)
    end
end

## CategoricalArray to sexp conversion.

function sexp(::Type{RClass{:factor}}, v::CategoricalArray)
    rv = protect(sexp(RClass{:integer}, v.refs))
    order = CategoricalArrays.order(v.pool)
    @inbounds for (i,ref) = enumerate(v.refs)
        if ref == 0
            rv[i] = naeltype(IntSxp)
        else
            rv[i] = order[ref]
        end
    end
    try
        setattrib!(rv, Const.LevelsSymbol, CategoricalArrays.levels(v))
        if CategoricalArrays.isordered(v)
            setattrib!(rv, Const.ClassSymbol, "factor")
        else
            setattrib!(rv, Const.ClassSymbol, ["ordered", "factor"])
        end
    finally
        unprotect(1)
    end
    rv
end
