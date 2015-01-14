module RCall
    using Compat,DataArrays,DataFrames
if VERSION < v"v0.4-"
    using Docile                        # for the @doc macro
#    @docstrings(manual=["../doc/manual.md"])
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

type SEXP{N}                    # N is the R SEXPREC type (see R_h.jl)
    p::Ptr{Void}
end
                                # determine the R SEXPREC type from the Ptr{Void}
sexp(p::Ptr{Void}) = SEXP{unsafe_load(convert(Ptr{Cint},p)) & 0x1f}(p)

Base.convert(::Type{Ptr{Void}},s::SEXP) = s.p  # for convenience in ccall

function __init__()
    argv = ["Rembed","--silent"]
    i = ccall((:Rf_initEmbeddedR,libR),Cint,(Cint,Ptr{Ptr{Uint8}}),length(argv),argv)
    i > 0 || error("initEmbeddedR failed.  Try running Pkg.build(\"RCall\").")
    global const R_NaInt =  unsafe_load(cglobal((:R_NaInt,libR),Cint),1)
    global const R_NaReal = unsafe_load(cglobal((:R_NaReal,libR),Cdouble),1)
    global const R_NaString = sexp(unsafe_load(cglobal((:R_NaString,libR),Ptr{Void}),1))
    global const classSymbol = sexp(unsafe_load(cglobal((:R_ClassSymbol,libR),Ptr{Void}),1))
    global const emptyEnv = sexp(unsafe_load(cglobal((:R_EmptyEnv,libR),Ptr{Void}),1))
    global const dimSymbol = sexp(unsafe_load(cglobal((:R_DimSymbol,libR),Ptr{Void}),1))
    global const globalEnv = sexp(unsafe_load(cglobal((:R_GlobalEnv,libR),Ptr{Void}),1))
    global const levelsSymbol = sexp(unsafe_load(cglobal((:R_LevelsSymbol,libR),Ptr{Void}),1))
    global const namesSymbol = sexp(unsafe_load(cglobal((:R_NamesSymbol,libR),Ptr{Void}),1))
    global const nilValue = sexp(unsafe_load(cglobal((:R_NilValue,libR),Ptr{Void}),1))
    rone = sexp(1.)
    ## offsets (in bytes) from the Ptr{Void} to an R object and its vector contents
    global const voffset = int(ccall((:REAL,libR),Ptr{Void},(Ptr{Void},),rone) - rone.p)
    ## offsets (in bytes) from the Ptr{Void} to an R object and its length
    global const loffset = voffset - 2*sizeof(Cint)
end

## Should there be a a function that cleans up and closes the current embedded R?

include("R_h.jl")
include("interface.jl")
include("sexp.jl")
include("rfuns.jl")

end # module
