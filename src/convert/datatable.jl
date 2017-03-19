# conversion methods for NullableArrays, CategoricalArrays and DataTables

function rcopy{T,S<:Sxp}(::Type{Nullable{T}}, s::Ptr{S})
    length(s) == 1 || error("length of s must be 1.")
    rcopy(NullableArray{T}, s)[1]
end

function rcopy{S<:VectorSxp}(::Type{Nullable}, s::Ptr{S})
    rcopy(Nullable{eltype(S)}, s)
end

function rcopy{S<:StrSxp}(::Type{Nullable}, s::Ptr{S})
    rcopy(Nullable{String}, s)
end

function rcopy{T,S<:VectorSxp}(::Type{NullableArray{T}}, s::Ptr{S})
    NullableArray(rcopy(Array{T},s), isna(s))
end
function rcopy{S<:VectorSxp}(::Type{NullableArray}, s::Ptr{S})
    NullableArray(rcopy(Array,s), isna(s))
end

function rcopy(::Type{NullableArray}, s::Ptr{IntSxp})
    isFactor(s) && error("s is an R factor")
    NullableArray(rcopy(Array,s), isna(s))
end
function rcopy(::Type{CategoricalArray}, s::Ptr{IntSxp})
    isFactor(s) || error("s is not an R factor")
    refs = UInt32[x for x in s]
    levels = rcopy(Array, getattrib(s,Const.LevelsSymbol))
    pool = CategoricalPool(levels, isOrdered(s))
    CategoricalArray(refs, pool)
end
function rcopy(::Type{NullableCategoricalArray}, s::Ptr{IntSxp})
    isFactor(s) || error("s is not an R factor")
    refs = UInt32[isna(x) ? zero(UInt32) : UInt32(x) for x in s]
    levels = rcopy(Array, getattrib(s,Const.LevelsSymbol))
    pool = CategoricalPool(levels, isOrdered(s))
    NullableCategoricalArray(refs, pool)
end

# DataTable
# function rcopy{T<:AbstractDataTable}(::Type{T}, s::Ptr{VecSxp}; sanitize::Bool=true)
#     isFrame(s) || error("s is not an R data frame")
#     vnames = rcopy(Vector{Symbol},getnames(s))
#     if sanitize
#         vnames = [Symbol(replace(string(v), '.', '_')) for v in vnames]
#     end
#     DataTable(
#         Any[isFactor(c)? rcopy(NullableCategoricalArray, c) : rcopy(NullableArray, c) for c in s],
#         vnames)
# end

# Nullable and NullableArray to sexp conversion.
for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp)
    @eval begin
        function sexp(::Type{$S}, x::Nullable)
            if isnull(x)
                return sexp($S, naeltype($S))
            else
                return sexp($S, x.value)
            end
        end
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

## CategoricalArray to sexp conversion.
for typ in [:NullableCategoricalArray, :CategoricalArray]
    @eval begin
        function sexp{T<:String,N,R<:Integer}(::Type{IntSxp}, v::$typ{T,N,R})
            rv = protect(sexp(v.refs))
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

# DataTable
# function sexp(::Type{VecSxp}, d::AbstractDataTable)
#     nr,nc = size(d)
#     nv = names(d)
#     rd = protect(allocArray(VecSxp, nc))
#     try
#         for i in 1:nc
#             rd[i] = sexp(d[nv[i]])
#         end
#         setattrib!(rd,Const.NamesSymbol, sexp([string(n) for n in nv]))
#         setattrib!(rd,Const.ClassSymbol, sexp("data.frame"))
#         setattrib!(rd,Const.RowNamesSymbol, sexp(1:nr))
#     finally
#         unprotect(1)
#     end
#     rd
# end
