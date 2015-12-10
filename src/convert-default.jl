# logic for default rcopy

"""
`rcopy` copies the contents of an R object into a corresponding canonical Julia type.
"""
rcopy(s::SymSxpPtr) = rcopy(Symbol,s)
rcopy(s::CharSxpPtr) = rcopy(AbstractString,s)

function rcopy(s::StrSxpPtr)
    if anyNA(s)
        rcopy(DataArray,s)
    elseif length(s) == 1
        rcopy(AbstractString,s)
    else
        rcopy(Array,s)
    end
end
function rcopy(s::RealSxpPtr)
    if anyNA(s)
        rcopy(DataArray{Float64},s)
    elseif length(s) == 1
        rcopy(Float64,s)
    else
        rcopy(Array{Float64},s)
    end
end
function rcopy(s::CplxSxpPtr)
    if anyNA(s)
        rcopy(DataArray{Complex128},s)
    elseif length(s) == 1
        rcopy(Complex128,s)
    else
        rcopy(Array{Complex128},s)
    end
end
function rcopy(s::LglSxpPtr)
    if anyNA(s)
        rcopy(DataArray{Bool},s)
    elseif length(s) == 1
        rcopy(Bool,s)
    else
        rcopy(BitArray,s)
    end
end
function rcopy(s::IntSxpPtr)
    if isFactor(s)
        rcopy(PooledDataArray,s)
    elseif anyNA(s)
        rcopy(DataArray{Int},s)
    elseif length(s) == 1
        rcopy(Cint,s)
    else
        rcopy(Array{Cint},s)
    end
end

function rcopy(s::VecSxpPtr)
    if isFrame(s)
        rcopy(DataFrame,s)
    elseif isNull(getNames(s))
        rcopy(Array{Any},s)
    else
        rcopy(Dict{Symbol,Any},s)
    end
end

rcopy(s::FunctionSxpPtr) = rcopy(Function,s)

# TODO
rcopy(l::LangSxpPtr) = l
rcopy(r::RObject{LangSxp}) = r
