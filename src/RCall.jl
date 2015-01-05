module RCall
    export globalEnv,
           libR,
           SEXP,
           SXPtype

if isfile(joinpath(dirname(@__FILE__),"..","deps","deps.jl"))
    include("../deps/deps.jl")
else
    error("RCall not properly installed. Please run Pkg.build(\"RCall\")")
end

using Compat#, DataArrays

# Instead of trying to reconstruct the internal representation of
# R's SEXPREC structure (and possibly get it wrong), just go through
# the R API from $R_INCLUDE_DIR/Rinternals.h.

immutable SEXP{N}                       # N is the R type value (e.g. 1=>SYMSXP)
    p::Ptr{Void}
end

asSEXP(p::Ptr{Void}) = SEXP{unsafe_load(convert(Ptr{Cint},p)) & 0x1f}(p)

SXPtype(s::SEXP{0}) = :NILSXP        # NULL in R
SXPtype(s::SEXP{1}) = :SYMSXP        # R Symbol
SXPtype(s::SEXP{2}) = :LISTSXP       # internal "pairs list", the R list type is 19
SXPtype(s::SEXP{3}) = :CLOSXP        # closures
SXPtype(s::SEXP{4}) = :ENVSXP        # environments
SXPtype(s::SEXP{5}) = :PROMSX        # promises: [un]evaluated closure arguments
SXPtype(s::SEXP{6}) = :LANGSXP       # language constructs (special lists)
SXPtype(s::SEXP{7}) = :SPECIALSXP    # special forms
SXPtype(s::SEXP{8}) = :BUILTINSXP    # builtin non-special forms
SXPtype(s::SEXP{9}) = :CHARSXP       # "scalar" string type (internal only)
SXPtype(s::SEXP{10}) = :LGLSXP        # logical vectors (but can contain NA's)
## 11 and 12 were factors and ordered factors in the 1990's
SXPtype(s::SEXP{13}) = :INTSXP        # Int32 vectors
SXPtype(s::SEXP{14}) = :REALSXP       # Float64 vectors
SXPtype(s::SEXP{15}) = :CPLXSXP       # Complex128 vectors
SXPtype(s::SEXP{16}) = :STRSXP        # string vectors
SXPtype(s::SEXP{17}) = :DOTSXP        # dot-dot-dot object
SXPtype(s::SEXP{18}) = :ANYSXP        # make "any" args work
SXPtype(s::SEXP{19}) = :VECSXP        # generic vectors (i.e. R's list type)
SXPtype(s::SEXP{20}) = :EXPSXP        # expression vectors (as returned by parse)
SXPtype(s::SEXP{21}) = :BCODESXP      # byte code
SXPtype(s::SEXP{22}) = :EXTPTRSXP     # external pointer
SXPtype(s::SEXP{23}) = :WEAKREFSXP    # weak references
SXPtype(s::SEXP{24}) = :RAWSXP        # raw bytes
SXPtype(s::SEXP{25}) = :S4SXP          # S4 non-vector
 
function __init__()
    argv = ["Rembed","--silent"]
    i = ccall((:Rf_initEmbeddedR,libR),Cint,(Cint,Ptr{Ptr{Uint8}}),length(argv),argv)
    i > 0 || error("initEmbeddedR failed")
    global const globalEnv = asSEXP(unsafe_load(cglobal((:R_GlobalEnv,libR),Ptr{Void}),1))
    global const emptyEnv = asSEXP(unsafe_load(cglobal((:R_EmptyEnv,libR),Ptr{Void}),1))
    global const namesSymbol = asSEXP(unsafe_load(cglobal((:R_NamesSymbol,libR),Ptr{Void}),1))
    global const classSymbol = asSEXP(unsafe_load(cglobal((:R_ClassSymbol,libR),Ptr{Void}),1))
    global const R_NaReal = unsafe_load(cglobal((:R_NaReal,libR),Cdouble),1)
    global const R_NaInt =  unsafe_load(cglobal((:R_NaInt,libR),Cint),1)
end

function Base.getindex(s::SEXP{19},I::Integer)
    0 < I ≤ length(s) || throw(BoundsError())
    asSEXP(ccall((:VECTOR_ELT,libR),Ptr{Void},(Ptr{Void},Cptrdiff_t),s.p,I-1))
end

Base.length(s::SEXP) = ccall((:Rf_length,libR),Int,(Ptr{Void},),s.p)

value(s::SEXP{0}) = nothing             # NULL in R
# R's (internal) CHARSXP type
value(s::SEXP{9}) = bytestring(ccall((:R_CHAR,libR),Ptr{Uint8},(Ptr{Void},),s.p))
# R's LGLSXP (logical type)  typemin(Int32) is NA, other non-zeros are true, 0 is false
value(s::SEXP{10}) = pointer_to_array(ccall((:LOGICAL,libR),Ptr{Cint},
                                            (Ptr{Void},),s.p),length(s))
# INTEGER (i.e. Int32) vector typemin(Int32) is NA
value(s::SEXP{10}) = pointer_to_array(ccall((:INTEGER,libR),Ptr{Cint},
                                            (Ptr{Void},),s.p),length(s))
# REAL (i.e. Float64) vector
value(s::SEXP{14}) = pointer_to_array(ccall((:REAL,libR),
                                            Ptr{Cdouble},(Ptr{Void},),s.p),length(s))
# COMPLEX (i.e. Complex128) vector
value(s::SEXP{15}) = pointer_to_array(ccall((:COMPLEX,libR),
                                            Ptr{Complex128},(Ptr{Void},),s.p),length(s))
value(s::SEXP{16}) = 
    ASCIIString[copy(value(asSEXP(ccall((:STRING_ELT,libR),Ptr{Void},(Ptr{Void},Cint),
                                              s.p,i-1)))) for i in 1:length(s)]

Base.names(s::SEXP) = value(asSEXP(ccall((:Rf_getAttrib,libR),Ptr{Void},
                                         (Ptr{Void},Ptr{Void}),s.p,namesSymbol.p)))

include("interface.jl")
end # module
