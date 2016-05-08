__precompile__()
module RCall
using DataFrames,DataArrays

import DataStructures: OrderedDict

import Base: eltype, show, convert, isascii,
    length, size, getindex, setindex!, start, next, done

export RObject,
   Sxp, NilSxp, StrSxp, CharSxp, LglSxp, IntSxp, RealSxp, CplxSxp,
   ClosSxp,
   getAttrib, setAttrib!, getNames, setNames!,
   globalEnv,
   rcopy, rparse, rprint, reval, rcall, rlang,
   isNA, anyNA, isFactor, isOrdered,
   @rimport, @rusing, @rlibrary, @rput, @rget, @var_str, @R_str


include("setup.jl")
include("types.jl")
include("constants.jl")
include("methods.jl")
include("convert-base.jl")
include("convert-data.jl")
include("convert-default.jl")
include("iface.jl")
include("io.jl")
include("functions.jl")
include("library.jl")
include("eventloop.jl")
include("callback.jl")
include("IJulia.jl")
include("rstr.jl")
include("operators.jl")

"""
R global Environment.

    globalEnv[:x] = 1
    globalEnv[:x]
"""
const globalEnv = Const.GlobalEnv



end # module
