__precompile__()
module RCall
using Compat

using Nulls
using DataArrays
using CategoricalArrays
using DataFrames
# using DataTables
using NullableArrays, AxisArrays, NamedArrays

import DataStructures: OrderedDict

import Base: eltype, convert, isascii, isnull,
    names, length, size, getindex, setindex!, start, next, done,
    show, showerror, write


if isdefined(DataFrames, :isna)
    import DataFrames: isna
elseif isdefined(DataArrays, :isna)
    import DataArrays: isna
end

export RObject,
   Sxp, NilSxp, StrSxp, CharSxp, LglSxp, IntSxp, RealSxp, CplxSxp,
   ListSxp, VecSxp, EnvSxp, LangSxp, ClosSxp, S4Sxp,
   getattrib, setattrib!, getnames, setnames!, getclass, setclass!, attributes,
   globalEnv,
   isna, anyna,
   rcopy, rparse, rprint, reval, rcall, rlang,
   rimport, @rimport, @rlibrary, @rput, @rget, @var_str, @R_str


include("setup.jl")
include("types.jl")
include("Const.jl")
include("methods.jl")
include("convert/base.jl")
include("convert/dataarray.jl")
include("convert/categorical.jl")
include("convert/datetime.jl")
include("convert/dataframe.jl")
# include("convert/datatable.jl")
include("convert/nullable.jl")
include("convert/axisarray.jl")
include("convert/namedarray.jl")
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
