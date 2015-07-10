module RCall
using Compat,DataArrays,DataFrames

if VERSION < v"v0.4-"
    using Docile                    # for the @doc macro
end

import Base: eltype, show, convert,
    length, size, getindex, setindex!, start, next, done

export RObject,
   SxpRec, StrSxpRec, LglSxpRec, IntSxpRec, RealSxpRec, CplxSxpRec,
   getAttrib, setAttrib!, getNames, setNames!,
   rGlobalEnv,
   rcopy, rparse, rprint, reval, rcall, rlang,
   isNA, anyNA, isFactor, isOrdered,
   @rimport, @rusing


if isfile(joinpath(dirname(@__FILE__),"..","deps","deps.jl"))
    include("../deps/deps.jl")
else
    error("RCall not properly installed. Please run Pkg.build(\"RCall\")")
end


include("types.jl")
include("methods.jl")
include("conversions.jl")
include("dataframes.jl")
include("iface.jl")
include("functions.jl")
include("library.jl")
include("eventloop.jl")

# only if using IJulia
# TODO: move to __init__
isdefined(Main, :IJulia) && Main.IJulia.inited && include("IJulia.jl")


type Rinstance                    # attach a finalizer to clean up
    i::Cint
    function Rinstance(i::Integer)
        v = new(convert(Cint,i))
        finalizer(v,i->ccall((:Rf_endEmbeddedR,libR),Void,(Cint,),0))
        v
    end
end


function __init__()
    argv = ["REmbeddedJulia","--silent","--no-save"]
    i = ccall((:Rf_initEmbeddedR,libR),Cint,(Cint,Ptr{Ptr{Uint8}}),length(argv),argv)
    i > 0 || error("initEmbeddedR failed.  Try running Pkg.build(\"RCall\").")
    global const Rproc = Rinstance(i)


    ip = ccall((:Rf_ScalarInteger,libR),Ptr{Void},(Int32,),0)
    global const voffset = ccall((:INTEGER,libR),Ptr{Void},(Ptr{Void},),ip) - ip


    global const rNaInt =  unsafe_load(cglobal((:R_NaInt,libR),Cint))
    global const rNaReal = unsafe_load(cglobal((:R_NaReal,libR),Cdouble))

    global const rNaString = unsafe_load(cglobal((:R_NaString,libR),CharSxp))
    global const rBlankString = unsafe_load(cglobal((:R_BlankString,libR),CharSxp))
    global const rBlankScalarString = unsafe_load(cglobal((:R_BlankScalarString,libR),Ptr{StrSxpRec}))

    for s in [:BaseSymbol,         # base
              :BraceSymbol,        # {
              :Bracket2Symbol,     # [[
              :BracketSymbol,      # [
              :ClassSymbol,        # class
              :DeviceSymbol,       # .Device
              :DimNamesSymbol,     # dimnames
              :DimSymbol,          # dim
              :DollarSymbol,       # $
              :DotsSymbol,         # ...
              :DoubleColonSymbol,  # ::
              :DropSymbol,         # drop
              :LastvalueSymbol,    # .Last.value
              :LevelsSymbol,       # levels
              :ModeSymbol,         # mode
              :NaRmSymbol,         # na.rm
              :NameSymbol,         # name
              :NamesSymbol,        # names
              :NamespaceEnvSymbol, # .__NAMESPACE__.
              :PackageSymbol,      # package
              :PreviousSymbol,     # previous
              :QuoteSymbol,        # quote
              :RowNamesSymbol,     # row.names
              :SeedsSymbol,        # .Random.seed
              :SortListSymbol,     # sort.lis
              :SourceSymbol,       # source
              :SpecSymbol,         # spec
              :TripleColonSymbol,  # :::
              :dot_defined,        # .defined
              :dot_Method,         # .Method
              :dot_packageName,    # .packageName
              :dot_target]         # .targe

        @eval global const $(symbol(string('r',s))) = unsafe_load(cglobal(($(string(:R_,s)),libR),Ptr{SymSxpRec}))
    end

    global const rEmptyEnv = unsafe_load(cglobal((:R_EmptyEnv,libR),Ptr{EnvSxpRec}))
    global const rGlobalEnv = unsafe_load(cglobal((:R_GlobalEnv,libR),Ptr{EnvSxpRec}))

    global const rNilValue = unsafe_load(cglobal((:R_NilValue,libR),Ptr{NilSxpRec}))
    global const rUnboundValue = unsafe_load(cglobal((:R_UnboundValue,libR),UnknownSxp))
    global const rMissingArg =  unsafe_load(cglobal((:R_MissingArg,libR),Ptr{SymSxpRec}))

end



end # module
