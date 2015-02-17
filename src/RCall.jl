module RCall
    using Compat,DataArrays,DataFrames

    if VERSION < v"v0.4-"
        using Docile                    # for the @doc macro
    end

    export globalEnv,
           R,
           SEXP,
           libR

    if isfile(joinpath(dirname(@__FILE__),"..","deps","deps.jl"))
        include("../deps/deps.jl")
    else
        error("RCall not properly installed. Please run Pkg.build(\"RCall\")")
    end

# Instead of trying to reconstruct the internal representation of
# R's SEXPREC structure (and possibly get it wrong), just go through
# the R API from ENV["R_INCLUDE_DIR"]/Rinternals.h.

    type SEXP{N}                # N is the R SEXPREC type (see R_h.jl)
        p::Ptr{Void}
    end
                                # determine the R SEXPREC type from the Ptr{Void}
    sexp(p::Ptr{Void}) = SEXP{unsafe_load(convert(Ptr{Cint},p)) & 0x1f}(p)

    Base.convert(::Type{Ptr{Void}},s::SEXP) = s.p  # for convenience in ccall

@doc """
  Initialize the module.

  Start an embedded R and create global values from several built-ins.
  In particular, globalEnv must be defined if any R expression is to be evaluated.

  The integer constant voffset is the number of bytes from the pointer to a
  vector SEXP to the beginning of its contents.  loffset is the offset to its length.
"""->
function __init__()                     
    argv = ["Rembed","--silent","--vanilla"]
    i = ccall((:Rf_initEmbeddedR,libR),Cint,(Cint,Ptr{Ptr{Uint8}}),length(argv),argv)
    i > 0 || error("initEmbeddedR failed.  Try running Pkg.build(\"RCall\").")
    global const R_NaInt =  unsafe_load(cglobal((:R_NaInt,libR),Cint))
    global const R_NaReal = unsafe_load(cglobal((:R_NaReal,libR),Cdouble))
    global const R_NaString = sexp(unsafe_load(cglobal((:R_NaString,libR),Ptr{Void})))
    global const classSymbol = sexp(unsafe_load(cglobal((:R_ClassSymbol,libR),Ptr{Void})))
    global const emptyEnv = sexp(unsafe_load(cglobal((:R_EmptyEnv,libR),Ptr{Void})))
    global const dimSymbol = sexp(unsafe_load(cglobal((:R_DimSymbol,libR),Ptr{Void})))
    global const globalEnv = sexp(unsafe_load(cglobal((:R_GlobalEnv,libR),Ptr{Void})))
    global const levelsSymbol = sexp(unsafe_load(cglobal((:R_LevelsSymbol,libR),Ptr{Void})))
    global const namesSymbol = sexp(unsafe_load(cglobal((:R_NamesSymbol,libR),Ptr{Void})))
    global const nilValue = sexp(unsafe_load(cglobal((:R_NilValue,libR),Ptr{Void})))
    rone = sexp(1.)
    ## offsets (in bytes) from the Ptr{Void} to an R object and its vector contents
    global const voffset = int(ccall((:REAL,libR),Ptr{Void},(Ptr{Void},),rone) - rone.p)
    ## offsets (in bytes) from the Ptr{Void} to an R object and its length
    global const loffset = voffset - 2*sizeof(Cint)
end

## Should there be a function that cleans up and closes the current embedded R?

    include("R_h.jl")
    include("interface.jl")
    include("sexp.jl")
    include("rfuns.jl")

end # module
