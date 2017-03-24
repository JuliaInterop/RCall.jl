__precompile__()
module RCall
using Compat

using DataFrames
# using DataTables
using NullableArrays, CategoricalArrays
using AxisArrays, NamedArrays

import DataStructures: OrderedDict

import Base: eltype, convert, isascii, isnull,
    names, length, size, getindex, setindex!, start, next, done,
    show, showerror, write

# issues/179
import DataFrames: isna

export RObject,
   Sxp, NilSxp, StrSxp, CharSxp, LglSxp, IntSxp, RealSxp, CplxSxp,
   ListSxp, VecSxp, EnvSxp, LangSxp, ClosSxp, S4Sxp,
   getattrib, setattrib!, getnames, setnames!, getclass, setclass!, attributes,
   globalEnv,
   isna, anyna,
   rcopy, rparse, rprint, reval, rcall, rlang,
   @rimport, @rlibrary, @rput, @rget, @var_str, @R_str


include("setup.jl")
include("types.jl")
include("Const.jl")
include("methods.jl")
include("convert/base.jl")
include("convert/dataframe.jl")
include("convert/datatable.jl")
include("convert/datetime.jl")
include("convert/axisarray.jl")
include("convert/namedarray.jl")
include("convert/default.jl")
include("eventloop.jl")
include("eval.jl")
include("io.jl")
include("Console.jl")
include("functions.jl")
include("callback.jl")
include("operators.jl")
include("library.jl")
include("render.jl")
include("macros.jl")
include("RPrompt.jl")
include("IJuliaHooks.jl")
include("deprecated.jl")

end # module
