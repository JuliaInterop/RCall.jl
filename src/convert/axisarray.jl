for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp)
    @eval begin
        function rcopy(::Type{AxisArray},s::Ptr{$S})
            protect(s)
            try
                class = rcopy(Symbol, getclass(s, true))
                return rcopy(AxisArray{eltype(RClass{class}, s)}, s)
            finally
                unprotect(1)
            end
        end
    end
end

function rcopy(::Type{AxisArray{T}}, r::Ptr{S}) where {S<:VectorSxp, T}
    dnames = getattrib(r, Const.DimNamesSymbol)
    isnull(dnames) && error("r has no dimnames")
    dsym = rcopy(Array{Symbol}, getnames(dnames))
    AxisArray(anyna(r) ? rcopy(DataArray{T}, r) : rcopy(Array{T}, r),
             [Axis{dsym[i]}(rcopy(n)) for (i,n) in enumerate(dnames)]...)
end


for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp)
    @eval begin
        function sexp(::Type{$S}, aa::AxisArray)
            rv = protect(sexp($S, aa.data))
            try
                d = OrderedDict(
                    k => v.val for (k, v) in zip(axisnames(aa), axes(aa)))
                setattrib!(rv, Const.DimSymbol, collect(size(aa)))
                setattrib!(rv, Const.DimNamesSymbol, d)
            finally
                unprotect(1)
            end
            rv
        end
    end
end
