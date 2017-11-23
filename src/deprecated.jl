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


function rcopy(::Type{PooledDataArray}, s::Ptr{IntSxp})
    Base.depwarn("Support for `PooledDataArray` is deprecated. Use `CategoricalArray` instead.", :rcopy)
    isFactor(s) || error("s is not an R factor")
    refs = DataArrays.RefArray([isNA(x) ? zero(Int32) : x for x in s])
    DataArrays.compact(PooledDataArray(refs, rcopy(Array, getattrib(s,Const.LevelsSymbol))))
end


## PooledDataArray to sexp conversion.
function sexp(::Type{IntSxp}, v::PooledDataArray{T,R}) where {T<:AbstractString,R<:Integer}
    Base.depwarn("Support for `PooledDataArray` is deprecated. Use `CategoricalArray` instead.", :sexp)
    rv = protect(sexp(IntSxp, v.refs))
    try
        for (i,r) = enumerate(v.refs)
            if r == 0
                rv[i] = naeltype(IntSxp)
            end
        end
    finally
        unprotect(1)
    end
    setattrib!(rv, Const.LevelsSymbol, sexp(v.pool))
    setattrib!(rv, Const.ClassSymbol, sexp("factor"))
    rv
end

# PooledDataArray
sexp(a::PooledDataArray) = sexp(IntSxp,a)
sexp(a::PooledDataArray{S}) where S<:AbstractString = sexp(IntSxp,a)


# NullableArrays


for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp)
    @eval begin
        function rcopy(::Type{NullableVector},s::Ptr{$S})
            protect(s)
            try
                class = rcopy(Symbol, getclass(s, true))
                return rcopy(NullableVector{eltype(RClass{class}, s)}, s)
            finally
                unprotect(1)
            end
        end
        function rcopy(::Type{NullableArray},s::Ptr{$S})
            protect(s)
            try
                class = rcopy(Symbol, getclass(s, true))
                return rcopy(NullableArray{eltype(RClass{class}, s)}, s)
            finally
                unprotect(1)
            end
        end
    end
end

function rcopy(::Type{NullableArray{T}}, s::Ptr{S}) where {T,S<:VectorSxp}
    Base.depwarn("Support for `NullableArray` is deprecated. Use `DataArray` instead.", :rcopy)
    NullableArray(rcopy(Array{T},s), isna(s))
end

function rcopy(::Type{NullableVector{T}}, s::Ptr{S}) where {T, S<:VectorSxp}
    Base.depwarn("Support for `NullableArray` is deprecated. Use `DataArray` instead.", :rcopy)
    NullableArray(rcopy(Vector{T},s), isna(s))
end

# Nullable and NullableArray to sexp conversion.
for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp)
    @eval begin
        function sexp(::Type{$S}, v::NullableArray)
            rv = protect(sexp($S, v.values))
            try
                for (i,isna) = enumerate(v.isnull)
                    if isna
                        rv[i] = naeltype($S)
                    end
                end
            finally
                unprotect(1)
            end
            rv
        end
    end
end
