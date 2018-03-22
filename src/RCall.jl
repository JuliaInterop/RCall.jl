__precompile__()
module RCall
using Compat

using Missings
using DataArrays
using CategoricalArrays
using DataFrames
using AxisArrays
import StatsModels:Formula
import DataStructures: OrderedDict

using Compat.Dates

if isdefined(DataArrays, :isna)
    import DataArrays: isna
end

if isdefined(DataArrays, :anyna)
    import DataArrays: anyna
end

import Base: eltype, convert, isascii, isnull,
    names, length, size, getindex, setindex!, start, next, done,
    show, showerror, write

export RObject,
   Sxp, NilSxp, StrSxp, CharSxp, LglSxp, IntSxp, RealSxp, CplxSxp,
   ListSxp, VecSxp, EnvSxp, LangSxp, ClosSxp, S4Sxp,
   getattrib, setattrib!, getnames, setnames!, getclass, setclass!, attributes,
   globalEnv,
   isna, anyna,
   rcopy, rparse, rprint, reval, rcall, rlang,
   rimport, @rimport, @rlibrary, @rput, @rget, @var_str, @R_str

const depfile = joinpath(dirname(@__FILE__),"..","deps","deps.jl")
if isfile(depfile)
    include(depfile)
else
    error("RCall not properly installed. Please run Pkg.build(\"RCall\")")
end

include("setup.jl")
include("types.jl")
include("Const.jl")
include("methods.jl")
include("convert/base.jl")
include("convert/missing.jl")
include("convert/dataarray.jl")
include("convert/categorical.jl")
include("convert/datetime.jl")
include("convert/dataframe.jl")
include("convert/formula.jl")
include("convert/nullable.jl")
include("convert/axisarray.jl")
include("convert/default.jl")
include("eventloop.jl")
include("eval.jl")
include("language.jl")
include("io.jl")
include("callback.jl")
include("namespaces.jl")
include("render.jl")
include("macros.jl")
include("operators.jl")
include("RPrompt.jl")
include("ijulia.jl")
include("deprecated.jl")

end # module
