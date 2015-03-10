module RCall
    using Compat,DataArrays,DataFrames

    if VERSION < v"v0.4-"
        using Docile                    # for the @doc macro
    end

    export SEXPREC,
           getAttrib,
           globalEnv,
           isFactor,
           isOrdered,
           isTs,
           libR,
           named,
           rcall,
           rcopy,
           reval,
           rparse,
           rprint,
           sexp


    if isfile(joinpath(dirname(@__FILE__),"..","deps","deps.jl"))
        include("../deps/deps.jl")
    else
        error("RCall not properly installed. Please run Pkg.build(\"RCall\")")
    end

    @doc "R symbolic expression"->
    abstract SEXPREC

    type Rinstance                    # attach a finalizer to clean up
        i::Cint
        function Rinstance(i::Integer)
            v = new(convert(Cint,i))
            finalizer(v,i->ccall((:Rf_endEmbeddedR,libR),Void,(Cint,),0))
        end
    end

@doc """
  Initialize the module.

  Start an embedded R and create global values from several built-ins.
  In particular, globalEnv must be defined if any R expression is to be evaluated.
"""->
function __init__()                     
    argv = ["Rembed","--silent","--no-save"]
    i = ccall((:Rf_initEmbeddedR,libR),Cint,(Cint,Ptr{Ptr{Uint8}}),length(argv),argv)
    i > 0 || error("initEmbeddedR failed.  Try running Pkg.build(\"RCall\").")
    global const Rproc = Rinstance(i)
    global const R_NaInt =  unsafe_load(cglobal((:R_NaInt,libR),Cint))
    global const R_NaReal = unsafe_load(cglobal((:R_NaReal,libR),Cdouble))
    ip = ccall((:Rf_ScalarInteger,libR),Ptr{Void},(Int32,),0)
    global const voffset = ccall((:INTEGER,libR),Ptr{Void},(Ptr{Void},),ip) - ip
    global const R_NaString = sexp(unsafe_load(cglobal((:R_NaString,libR),Ptr{Void})))
    global const classSymbol = sexp(unsafe_load(cglobal((:R_ClassSymbol,libR),Ptr{Void})))
    global const emptyEnv = sexp(unsafe_load(cglobal((:R_EmptyEnv,libR),Ptr{Void})))
    global const dimSymbol = sexp(unsafe_load(cglobal((:R_DimSymbol,libR),Ptr{Void})))
    global const globalEnv = sexp(unsafe_load(cglobal((:R_GlobalEnv,libR),Ptr{Void})))
    global const levelsSymbol = sexp(unsafe_load(cglobal((:R_LevelsSymbol,libR),Ptr{Void})))
    global const namesSymbol = sexp(unsafe_load(cglobal((:R_NamesSymbol,libR),Ptr{Void})))
    global const nilValue = sexp(unsafe_load(cglobal((:R_NilValue,libR),Ptr{Void})))
end

    include("types.jl")                 # define the various types of SEXPREC
    include("sexp.jl")
    include("iface.jl")
    include("show.jl")
    include("functions.jl")

end # module
