# conversion methods for CategoricalArrays

if Pkg.installed("CategoricalArrays") < v"0.2.0"
    function rcopy(::Type{CategoricalArray}, s::Ptr{IntSxp})
        isFactor(s) || error("s is not an R factor")
        refs = UInt32[x for x in s]
        levels = rcopy(Array{String}, getattrib(s,Const.LevelsSymbol))
        pool = CategoricalPool(levels, isOrdered(s))
        CategoricalArray(refs, pool)
    end
    function rcopy(::Type{NullableCategoricalArray}, s::Ptr{IntSxp})
        isFactor(s) || error("s is not an R factor")
        refs = UInt32[isNA(x) ? zero(UInt32) : UInt32(x) for x in s]
        levels = rcopy(Array{String}, getattrib(s,Const.LevelsSymbol))
        pool = CategoricalPool(levels, isOrdered(s))
        NullableCategoricalArray(refs, pool)
    end
else
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
end

## CategoricalArray to sexp conversion.
if Pkg.installed("CategoricalArrays") < v"0.2.0"
    CAtypes = [:NullableCategoricalArray, :CategoricalArray]
else
    CAtypes = [:CategoricalArray]
end

for typ in CAtypes
    @eval begin
        function sexp(::Type{IntSxp}, v::$typ)
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
    end
end
