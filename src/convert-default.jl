# logic for default rcopy

"""
`rcopy` copies the contents of an R object into a corresponding canonical Julia type.
"""
rcopy(s::SymSxpPtr) = rcopy(Symbol,s)
rcopy(s::CharSxpPtr) = rcopy(Compat.String,s)

function rcopy(s::StrSxpPtr)
    if anyna(s)
        rcopy(DataArray,s)
    elseif length(s) == 1
        rcopy(Compat.String,s)
    else
        rcopy(Array{Compat.String},s)
    end
end
function rcopy(s::RealSxpPtr)
    if anyna(s)
        rcopy(DataArray{Float64},s)
    elseif length(s) == 1
        rcopy(Float64,s)
    else
        rcopy(Array{Float64},s)
    end
end
function rcopy(s::CplxSxpPtr)
    if anyna(s)
        rcopy(DataArray{Complex128},s)
    elseif length(s) == 1
        rcopy(Complex128,s)
    else
        rcopy(Array{Complex128},s)
    end
end
function rcopy(s::LglSxpPtr)
    if anyna(s)
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
    elseif anyna(s)
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
    elseif isnull(getnames(s))
        rcopy(Array{Any},s)
    else
        rcopy(Dict{Symbol,Any},s)
    end
end

rcopy(s::FunctionSxpPtr) = rcopy(Function,s)

# TODO
rcopy(l::LangSxpPtr) = l
rcopy(r::RObject{LangSxp}) = r
