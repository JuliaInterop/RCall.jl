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
## should be extended to check for the sentinal value (typemin(Cint)) followed by extraction
## of the Int64 length.
for N in [10,13:16,19,20]
    @eval Base.length(s::SEXP{$N}) = unsafe_load(convert(Ptr{Cint},s.p+loffset),1)
end

## Element extraction and iterators
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

## ToDo: write an isNA method for Complex128 - not sure how it is defined though.
isNA(x::Cdouble) = x == R_NaReal
isNA(x::Cint) = x == R_NaInt
isNA(a::Array) = reshape(BitArray([isNA(aa) for aa in a]),size(a))

## bytestring copies the contents of the 0-terminated string at the Ptr{Uint8} address
Base.bytestring(s::SEXP{9}) = bytestring(ccall((:R_CHAR,libR),Ptr{Uint8},(Ptr{Void},),s.p))

for N in [10,13:16,19,20]
    @eval begin
        function Base.size(s::SEXP{$N})
            dd = Reval(lang2(dimSymbol,s))
            isa(dd,SEXP{13}) || return (int64(length(s)),)
            vv = vec(dd)
            ntuple(length(vv),i->Int64(vv[i]))
        end
    end
end

Base.vec(s::SEXP{16}) = [bytestring(ss) for ss in s]

for (N,typ) in ((10,:Int32),(13,:Int32),(14,:Float64),(15,:Complex128))
    @eval begin
        function Base.vec(s::SEXP{$N})
            ccall((:R_PreserveObject,libR),Void,(Ptr{Void},),s)
            rv = pointer_to_array(convert(Ptr{$typ},s.p+voffset),length(s))
            finalizer(rv,x->ccall((:R_ReleaseObject,libR),Void,(Ptr{Void},),s.p))
            rv
        end
    end
end

## Not sure what to do about R's Logical vectors (SEXP{10}) They are stored as Int32 and can
## have missing values.  The DataArray method must copy the values if it is to produce Bool's.
## For the time being, I will leave them as Int32's.
for N in [10,13:15]
    @eval begin
        DataArrays.DataArray(s::SEXP{$N}) = (rv = reshape(vec(s),size(s));DataArray(rv,isNA(rv)))
        dataset(s::SEXP{$N}) = DataArray(s)
    end
end

## ToDo: expand these definitions to check for names and produce NamedArrays?

# make dataset more general for integer vectors, which can be factors
dataset(s::SEXP{13}) =
    isFactor(s) ? compact(PooledDataArray(DataArrays.RefArray(vec(s)),R.levels(s))) : DataArray(s)

Base.names(s::SEXP) = vec(asSEXP(ccall((:Rf_getAttrib,libR),Ptr{Void},
                                       (Ptr{Void},Ptr{Void}),s,namesSymbol)))

function dataset(s::SEXP{19})
    val = [dataset(v) for v in s]
    R.inherits(s,"data.frame") ? DataFrame(val,Symbol[symbol(nm) for nm in names(s)]) : val
end

@doc "convert a symbol or ASCIIString to a dataset"->
dataset(s::Symbol) = dataset(Reval(s))
