function rcopy{S<:VectorSxp}(::Type{NamedArray}, r::Ptr{S})
    dnames = getattrib(r, Const.DimNamesSymbol)
    isnull(dnames) && error("r has no dimnames")
    d = [rcopy(Vector{String}, n) for n in dnames]
    NamedArray(rcopy(Array, r), d, rcopy(Vector{Symbol}, getnames(dnames)))
end

for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp)
    @eval begin
        function sexp(::Type{$S}, na::NamedArray)
            rv = protect(sexp($S, na.array))
            try
                d = OrderedDict(
                    k => v for (k, v) in zip(dimnames(na), names(na)))
                setattrib!(rv, Const.DimSymbol, collect(size(na)))
                setattrib!(rv, Const.DimNamesSymbol, d)
            finally
                unprotect(1)
            end
            rv
        end
    end
end
