module RCall

using Preferences
using Requires
using Dates
using Libdl
using Random
using REPL
if VERSION ≤ v"1.1.1"
   using Missings
end
using CategoricalArrays
using DataFrames
using StatsModels

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

# These two preference get marked as compile-time preferences by being accessed
# here
const Rhome_set_as_preference = @has_preference("Rhome")
const libR_set_as_preference = @has_preference("libR")

if Rhome_set_as_preference || libR_set_as_preference
    if !(Rhome_set_as_preference && libR_set_as_preference)
        error("RCall: Either both Rhome and libR must be set or neither of them")
    end
    const Rhome = @load_preference("Rhome")
    const libR = @load_preference("libR")
    const conda_provided_r = false
else
    const depfile = joinpath(dirname(@__FILE__),"..","deps","deps.jl")
    if isfile(depfile)
        include(depfile)
    else
        error("RCall not properly installed. Please run Pkg.build(\"RCall\")")
    end
end

if Rhome == ""
    @info (
        "No R installation found by RCall.jl. " *
        "Precompilation of RCall and all dependent packages postponed. " *
        "Importing RCall will fail until an R installation is configured beforehand."
    )
    __precompile__(false)
end

include("types.jl")
include("Const.jl")
include("methods.jl")
include("convert/base.jl")
include("convert/missing.jl")
include("convert/categorical.jl")
include("convert/datetime.jl")
include("convert/dataframe.jl")
include("convert/formula.jl")
include("convert/namedtuple.jl")
include("convert/tuple.jl")

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
include("setup.jl")
include("deprecated.jl")

end # module
