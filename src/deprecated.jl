module IJuliaHooks
    using RCall
    function ijulia_init()
        Base.depwarn("""
            `Use RCall.ijulia_init() instead.`.
        """, :ijulia_init)
        RCall.ijulia_init()
    end

    function ijulia_setdevice(args...; kwargs...)
        Base.depwarn("""
            `Use RCall.ijulia_setdevice(...) instead.`.
        """, :ijulia_init)
        RCall.ijulia_setdevice(args...; kwargs...)
    end
end

function rcopy(::Type{NamedArray}, r::Ptr{S}) where S<:VectorSxp
    Base.depwarn("Support for `NamedArray` is deprecated. Use `AxisArray` instead.", :rcopy)
    dnames = getattrib(r, Const.DimNamesSymbol)
    isnull(dnames) && error("r has no dimnames")
    d = [rcopy(Vector{String}, n) for n in dnames]
    NamedArray(rcopy(DataArray, r), d, rcopy(Vector{Symbol}, getnames(dnames)))
end

for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp)
    @eval begin
        function sexp(::Type{$S}, na::NamedArray)
            Base.depwarn("Support for `NamedArray` is deprecated. Use `AxisArray` instead.", :sexp)
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

for (J,S) in ((:Integer,:IntSxp),
                 (:AbstractFloat, :RealSxp),
                 (:Complex, :CplxSxp),
                 (:Bool, :LglSxp),
                 (:AbstractString, :StrSxp))
    @eval sexp(aa::NamedArray{T}) where T<:$J = sexp($S, aa)
end
