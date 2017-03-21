function rcopy{S<:VectorSxp}(::Type{AxisArray}, r::Ptr{S})
    dnames = getattrib(r, Const.DimNamesSymbol)
    isnull(dnames) && error("r has no dimnames")
    dsym = rcopy(Array{Symbol}, getnames(dnames))
    AxisArray(rcopy(Array, r), [Axis{dsym[i]}(rcopy(n)) for (i,n) in enumerate(dnames)]...)
end


for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp)
    @eval begin
        function sexp(::Type{$S}, aa::AxisArray)
            rv = protect(sexp($S, aa.data))
            try
                d = OrderedDict(
                    k => v.val for (k, v) in zip(axisnames(aa), axes(aa)))
                setattrib!(rv, Const.ClassSymbol, "array")
                setattrib!(rv, Const.DimSymbol, collect(size(aa)))
                setattrib!(rv, Const.DimNamesSymbol, d)
            finally
                unprotect(1)
            end
            rv
        end
    end
end
