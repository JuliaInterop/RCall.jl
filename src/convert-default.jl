# logic for default rcopy

"""
`rcopy` copies the contents of an R object into a corresponding canonical Julia type.
"""
rcopy(s::SymSxpPtr) = rcopy(Symbol,s)
rcopy(s::CharSxpPtr) = rcopy(String,s)

function rcopy(s::StrSxpPtr)
    if anyna(s)
        rcopy(NullableArray,s)
    elseif length(s) == 1
        rcopy(String,s)
    else
        rcopy(Array{String},s)
    end
end
function rcopy(s::RealSxpPtr)
    T = Float64
    classPtr = sexp(getclass(s))
    if typeof(classPtr) == StrSxpPtr
        class = rcopy(Vector{String}, classPtr)
        if  "Date" in class
            T = Date
        elseif "POSIXct" in class
            T = DateTime
        end
    end
    if anyna(s)
        rcopy(NullableArray{T},s)
    elseif length(s) == 1
        rcopy(T,s)
    else
        rcopy(Array{T},s)
    end
end
function rcopy(s::CplxSxpPtr)
    if anyna(s)
        rcopy(NullableArray{Complex128},s)
    elseif length(s) == 1
        rcopy(Complex128,s)
    else
        rcopy(Array{Complex128},s)
    end
end
function rcopy(s::LglSxpPtr)
    if anyna(s)
        rcopy(NullableArray{Bool},s)
    elseif length(s) == 1
        rcopy(Bool,s)
    else
        rcopy(BitArray,s)
    end
end
function rcopy(s::IntSxpPtr)
    if isFactor(s)
        if anyna(s)
            rcopy(NullableCategoricalArray,s)
        else
            rcopy(CategoricalArray,s)
        end
    elseif anyna(s)
        rcopy(NullableArray{Int},s)
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
