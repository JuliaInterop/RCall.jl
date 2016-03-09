__precompile__()
module RCall
using DataFrames,DataArrays

import Base: eltype, show, convert, isascii,
    length, size, getindex, setindex!, start, next, done

export RObject,
   Sxp, NilSxp, StrSxp, CharSxp, LglSxp, IntSxp, RealSxp, CplxSxp,
   ClosSxp,
   getAttrib, setAttrib!, getNames, setNames!,
   globalEnv,
   rcopy, rparse, rprint, reval, rcall, rlang,
   isNA, anyNA, isFactor, isOrdered,
   @rimport, @rusing, @rput, @rget, @var_str


include("setup.jl")
include("types.jl")
include("constants.jl")
include("methods.jl")
include("convert-base.jl")
include("convert-data.jl")
include("convert-default.jl")
include("iface.jl")
include("functions.jl")
include("library.jl")
include("eventloop.jl")
include("callback.jl")
include("IJulia.jl")
include("io.jl")


const globalEnv = Const.GlobalEnv



end # module
