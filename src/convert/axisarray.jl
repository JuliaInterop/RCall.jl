function rcopy{S<:VectorSxp}(::Type{AxisArray}, r::Ptr{S})
    dnames = getattrib(r, Const.DimNamesSymbol)
    isnull(dnames) && error("r has no dimnames")
    dsym = rcopy(Array{Symbol}, getnames(dnames))
    axes = [Axis{dsym[i]}(rcopy(n)) for (i,n) in enumerate(dnames)]
    AxisArray(rcopy(Array, r), axes...)
end


for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp)
    @eval begin
        function sexp(::Type{$S}, aa::AxisArray)
            rv = protect(sexp($S, aa.data))
            try
                d = OrderedDict(
                    k => v.val for (k, v) in zip(AxisArrays.axisnames(aa), AxisArrays.axes(aa)))
                setattrib!(rv, Const.DimNamesSymbol, sexp(VecSxp, d))
            finally
                unprotect(1)
            end
            rv
        end
    end
end
