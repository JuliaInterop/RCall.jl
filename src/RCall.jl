__precompile__()
module RCall

using Requires
using Dates
using Libdl
using Random
using REPL
using Missings
using CategoricalArrays
using DataFrames

import StatsModels: Formula, parse!
import DataStructures: OrderedDict

import Base: eltype, convert, isascii,
    names, length, size, getindex, setindex!,
    show, showerror, write
import Base.Iterators: iterate, IteratorSize, IteratorEltype, Pairs, pairs

export RObject,
   Sxp, NilSxp, StrSxp, CharSxp, LglSxp, IntSxp, RealSxp, CplxSxp,
   ListSxp, VecSxp, EnvSxp, LangSxp, ClosSxp, S4Sxp,
   getattrib, setattrib!, getnames, setnames!, getclass, setclass!, attributes,
   globalEnv,
   isnull, isna, anyna,
   robject, rcopy, rparse, rprint, reval, rcall, rlang,
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
include("convert/categorical.jl")
include("convert/datetime.jl")
include("convert/dataframe.jl")
include("convert/formula.jl")

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
