module RCallAxisArraysExt

using AxisArrays
using RCall

using RCall: Const, RClass, OrderedDict, VectorSxp, protect, sexp, unprotect

function RCall.rcopy(::Type{AxisArray}, r::Ptr{S}) where {S<:VectorSxp}
    dnames = getattrib(r, Const.DimNamesSymbol)
    isnull(dnames) && error("r has no dimnames")
    dsym = rcopy(Array{Symbol}, getnames(dnames))
    for i in eachindex(dsym)
        if dsym[i] == Symbol("")
            dsym[i] = i == 1 ? (:row) : i == 2 ? (:col) : i == 3 ? (:page) : Symbol(:dim_, i)
        end
    end
    as = Any[]
    for (i,n) in enumerate(dnames)
        push!(as, Axis{dsym[i]}(isnull(n) ? (1:(size(r)[i])) : rcopy(n)))
    end
    AxisArray(rcopy(AbstractArray, r), as...)
end

function RCall.sexp(::Type{RClass{:array}}, aa::AxisArray)
    rv = protect(sexp(aa.data))
    try
        d = OrderedDict(
            k => v.val for (k, v) in zip(axisnames(aa), AxisArrays.axes(aa)))
        setattrib!(rv, Const.DimSymbol, collect(size(aa)))
        setattrib!(rv, Const.DimNamesSymbol, d)
    finally
        unprotect(1)
    end
    rv
end

RCall.sexpclass(v::AxisArray) = RClass{:array}

end  # module
