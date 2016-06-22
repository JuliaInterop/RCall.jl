__precompile__()
module RCall
using Compat, DataFrames, DataArrays
import Compat.String

import DataStructures: OrderedDict

import Base: eltype, show, convert, isascii,
    length, size, getindex, setindex!, start, next, done

export RObject,
   Sxp, NilSxp, StrSxp, CharSxp, LglSxp, IntSxp, RealSxp, CplxSxp, ClosSxp,
   getAttrib, setAttrib!, getNames, setNames!,
   globalEnv,
   rcopy, rparse, rprint, reval, rcall, rlang,
   @rimport, @rlibrary, @rput, @rget, @var_str, @R_str


include("setup.jl")
include("types.jl")
include("constants.jl")
include("methods.jl")
include("convert-base.jl")
include("convert-data.jl")
include("convert-default.jl")
include("eventloop.jl")
include("eval.jl")
include("io.jl")
include("functions.jl")
include("callback.jl")
include("operators.jl")
include("library.jl")
include("IJulia.jl")
include("render.jl")
include("macros.jl")
include("repl.jl")

end # module
