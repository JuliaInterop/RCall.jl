module RCall
    using Compat,DataArrays,DataFrames
if VERSION < v"v0.4-"
    using Docile                        # for the @doc macro
end

    export globalEnv,
           libR,
           R,
           SEXP,
           SXPtype

if isfile(joinpath(dirname(@__FILE__),"..","deps","deps.jl"))
    include("../deps/deps.jl")
else
    error("RCall not properly installed. Please run Pkg.build(\"RCall\")")
end

# Instead of trying to reconstruct the internal representation of
# R's SEXPREC structure (and possibly get it wrong), just go through
# the R API from $R_INCLUDE_DIR/Rinternals.h.

immutable SEXP{N}                       # N is the R type value (e.g. 1=>SYMSXP)
    p::Ptr{Void}
end

asSEXP(p::Ptr{Void}) = SEXP{unsafe_load(convert(Ptr{Cint},p)) & 0x1f}(p)

Base.convert(::Type{Ptr{Void}},s::SEXP) = s.p  # for convenience in ccall

function __init__()
    argv = ["Rembed","--silent"]
    i = ccall((:Rf_initEmbeddedR,libR),Cint,(Cint,Ptr{Ptr{Uint8}}),length(argv),argv)
    i > 0 || error("initEmbeddedR failed")
    global const R_NaInt =  unsafe_load(cglobal((:R_NaInt,libR),Cint),1)
    global const R_NaReal = unsafe_load(cglobal((:R_NaReal,libR),Cdouble),1)
    global const classSymbol = asSEXP(unsafe_load(cglobal((:R_ClassSymbol,libR),Ptr{Void}),1))
    global const emptyEnv = asSEXP(unsafe_load(cglobal((:R_EmptyEnv,libR),Ptr{Void}),1))
    global const globalEnv = asSEXP(unsafe_load(cglobal((:R_GlobalEnv,libR),Ptr{Void}),1))
    global const levelsSymbol = asSEXP(unsafe_load(cglobal((:R_LevelsSymbol,libR),Ptr{Void}),1))
    global const namesSymbol = asSEXP(unsafe_load(cglobal((:R_NamesSymbol,libR),Ptr{Void}),1))
    global const nilValue = asSEXP(unsafe_load(cglobal((:R_NilValue,libR),Ptr{Void}),1))
    rone = scalarReal(1.)
    ## offsets (in bytes) from the Ptr{Void} to an R object and its vector contents
    global const voffset = Int(ccall((:REAL,libR),Ptr{Void},(Ptr{Void},),rone) - rone.p)
    ## offsets (in bytes) from the Ptr{Void} to an R object and its length
    global const loffset = voffset - 2*sizeof(Cint)
end

## Should there be a a function that cleans up and closes the current embedded R?

include("sexp.jl")
include("interface.jl")
include("Rfuns.jl")

end # module
