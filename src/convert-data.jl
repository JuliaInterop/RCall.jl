# conversion methods for DataArrays and DataFrames

function rcopy{T,S<:VectorSxp}(::Type{DataArray{T}}, s::Ptr{S})
    DataArray(rcopy(Array{T},s), isNA(s))
end
function rcopy{S<:VectorSxp}(::Type{DataArray}, s::Ptr{S})
    DataArray(rcopy(Array,s), isNA(s))
end

function rcopy(::Type{DataArray}, s::Ptr{IntSxp})
    isFactor(s) && error("$s is a R factor")
    DataArray(rcopy(Array,s), isNA(s))
end
function rcopy(::Type{PooledDataArray}, s::Ptr{IntSxp})
    isFactor(s) || error("$s is not a R factor")
    refs = DataArrays.RefArray([x == rNaInt ? zero(Int32) : x for x in s])
    compact(PooledDataArray(refs,rcopy(getAttrib(s,rLevelsSymbol))))
end
rcopy{S<:VectorSxp}(::Type{AbstractDataArray}, s::Ptr{S}) = rcopy(DataArray, s)
rcopy(::Type{AbstractDataArray}, s::Ptr{IntSxp}) =
    isFactor(s) ? rcopy(PooledDataArray,s) : rcopy(DataArray,s)

function rcopy(::Type{DataFrame}, s::Ptr{VecSxp})
    isFrame(s) || error("s is not a R data frame")
    DataFrame([rcopy(AbstractDataArray, c) for c in s],
              rcopy(Array{Symbol},getNames(s)))
end


## DataArray to sexp conversion.
function sexp(v::DataArray)
    rv = protect(sexp(v.data))
    for (i,isna) = enumerate(v.na)
        if isna
            rv[i] = NAel(eltype(rv))
        end
    end
    unprotect(1)
    rv
end

## PooledDataArray to sexp conversion.
function sexp{T<:ByteString,R<:Integer}(v::PooledDataArray{T,R})
    rv = sexp(v.refs)
    setAttrib!(rv, rLevelsSymbol, sexp(v.pool))
    setAttrib!(rv, rClassSymbol, sexp("factor"))
    rv
end

## DataFrame to sexp conversion.
function sexp(d::DataFrame)
    nr,nc = size(d)
    rd = protect(allocArray(VecSxp, nc))
    for i in 1:nc
        rd[i] = sexp(d[d.colindex.names[i]])
    end
    setAttrib!(rd,rNamesSymbol, sexp([string(n) for n in d.colindex.names]))
    setAttrib!(rd,rClassSymbol, sexp("data.frame"))
    setAttrib!(rd,rRowNamesSymbol, sexp(1:nr))
    unprotect(1)
    rd
end


# R formula objects
function sexp(f::Formula)
    s = protect(rlang_p(:~,rlang_formula(f.lhs),rlang_formula(f.rhs)))
    setAttrib!(s,rClassSymbol,sexp("formula"))
    setAttrib!(s,".Environment",rGlobalEnv)
    unprotect(1)
    s
end

function rlang_formula(e::Expr)
    e.head == :call || error("invalid formula object")
    op = e.args[1]
    if op == :&
        op = :(:)
    end
    if length(e.args) > 3 && op in (:+,:*,:(:))
        rlang_p(op,
                rlang_formula(Expr(e.head,e.args[1:end-1]...)),
                rlang_formula(e.args[end]))
    else
        rlang_p(op,map(rlang_formula,e.args[2:end])...)
    end
end
rlang_formula(e::Symbol) = e
        
