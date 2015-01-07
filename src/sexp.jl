# not sure these methods are needed, perhaps just a comment will do.
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


## length methods for the vector types of SEXP's.  To handle long vectors the length method
## should be extended to check for a value of typemin(Cint) and then extract the long length
for N in [10,13:16,19,20]
    @eval Base.length(s::SEXP{$N}) = unsafe_load(convert(Ptr{Cint},s.p+loffset),1)
end

for (N,elt) in ((16,:STRING_ELT),(19,:VECTOR_ELT),(20,:VECTOR_ELT))
    @eval begin
        function Base.getindex(s::SEXP{$N},I::Number)  # extract a single element
            0 < I ≤ length(s) || throw(BoundsError())
            asSEXP(ccall(($(string(elt)),libR),Ptr{Void},(Ptr{Void},Cint),s,I-1))
        end
        Base.start(s::SEXP{$N}) = 0  # start,next,done and eltype provide an iterator
        Base.next(s::SEXP{$N},state) = (state += 1;(s[state],state))
        Base.done(s::SEXP{$N},state) = state ≥ length(s)
        Base.eltype(s::SEXP{$N}) = SEXP
    end
end
Base.eltype(s::SEXP{16}) = SEXP{9}      # be more specific for STRSXP

isNA(x::Cdouble) = x == R_NaReal
isNA(x::Cint) = x == R_NaInt
isNA(a::Array) = reshape(BitArray([isNA(aa) for aa in a]),size(a))

for (N,typ) in ((10,:Int32),(13,:Int32),(14,:Float64),(15,:Complex128))
    @eval rawvector(s::SEXP{$N}) = pointer_to_array(convert(Ptr{$typ},s.p+voffset),length(s))
end

for N in [10,14,15]
    @eval DataArrays.DataArray(s::SEXP{$N}) = (rv = rawvector(s);DataArray(rv,isNA(rv)))
end

function DataArrays.DataArray(s::SEXP{13}) # could be a factor
    rv = rawvector(s)
    isFactor(s) ? PooledDataArray(DataArrays.RefArray(rv),R.levels(s)) : DataArray(rv,isNA(rv))
end

# R's (internal) CHARSXP type
Base.string(s::SEXP{9}) = bytestring(ccall((:R_CHAR,libR),Ptr{Uint8},(Ptr{Void},),s))

rawvector(s::SEXP{16}) = ASCIIString[copy(string(ss)) for ss in s]

Base.names(s::SEXP) = rawvector(asSEXP(ccall((:Rf_getAttrib,libR),Ptr{Void},
                                             (Ptr{Void},Ptr{Void}),s,namesSymbol)))
