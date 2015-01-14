## Methods related to the SEXP (pointer to SEXPREC type) in R

## length methods for the vector types of SEXP's.  To handle long vectors the length method
## should be extended to check for the sentinal value (typemin(Cint)) followed by extraction
## of the Int64 length.  The size methods check for a dim attribute and return a tuple.
for N in [LGLSXP,INTSXP,REALSXP,CPLXSXP,STRSXP,VECSXP,EXPRSXP]
    @eval begin
        Base.length(s::SEXP{$N}) = unsafe_load(convert(Ptr{Cint},s.p+loffset),1)
        function Base.size(s::SEXP{$N})
            dd = reval(lang2(dimSymbol,s))
            isa(dd,SEXP{INTSXP}) || return (int64(length(s)),)
            vv = vec(dd)
            ntuple(length(vv),i->int64(vv[i]))
        end
    end
end

## Element extraction and iterators
for (N,elt) in ((STRSXP,:STRING_ELT),(VECSXP,:VECTOR_ELT),(EXPRSXP,:VECTOR_ELT))
    @eval begin
        function Base.getindex(s::SEXP{$N},I::Number)  # extract a single element
            0 < I ≤ length(s) || throw(BoundsError())
            sexp(ccall(($(string(elt)),libR),Ptr{Void},(Ptr{Void},Cint),s,I-1))
        end
        Base.start(s::SEXP{$N}) = 0  # start,next,done and eltype provide an iterator
        Base.next(s::SEXP{$N},state) = (state += 1;(s[state],state))
        Base.done(s::SEXP{$N},state) = state ≥ length(s)
        Base.eltype(s::SEXP{$N}) = SEXP
    end
end
Base.eltype(s::SEXP{STRSXP}) = SEXP{CHARSXP} # be more specific for STRSXP

## ToDo: write an isNA method for Complex128 - not sure how it is defined though.
isNA(x::Cdouble) = x == R_NaReal
isNA(x::Cint) = x == R_NaInt
isNA(x::Union(ASCIIString,UTF8String)) = x == bytestring(R_NaString)
isNA(a::Array) = reshape(bitpack([isNA(aa) for aa in a]),size(a))

## bytestring copies the contents of the 0-terminated string at the Ptr{Uint8} address
Base.bytestring(s::SEXP{CHARSXP}) = bytestring(ccall((:R_CHAR,libR),Ptr{Uint8},(Ptr{Void},),s))

Base.vec(s::SEXP{STRSXP}) = [bytestring(ss) for ss in s]

for (N,typ) in ((LGLSXP,:Int32),(INTSXP,:Int32),(REALSXP,:Float64),(CPLXSXP,:Complex128))
    @eval begin
        function Base.vec(s::SEXP{$N})
            ccall((:R_PreserveObject,libR),Void,(Ptr{Void},),s)
            rv = pointer_to_array(convert(Ptr{$typ},s.p+voffset),length(s))
            finalizer(rv,x->ccall((:R_ReleaseObject,libR),Void,(Ptr{Void},),s))
            rv
        end
    end
end

## Not sure what to do about R's Logical vectors (SEXP{10}) They are stored as Int32 and can
## have missing values.  The DataArray method must copy the values if it is to produce Bool's.
## For the time being, I will leave them as Int32's.
for N in [LGLSXP,INTSXP,REALSXP,CPLXSXP,STRSXP]
    @eval begin
        DataArrays.DataArray(s::SEXP{$N}) = (rv = reshape(vec(s),size(s));DataArray(rv,isNA(rv)))
        dataset(s::SEXP{$N}) = DataArray(s)
    end
end

## ToDo: expand these definitions to check for names and produce NamedArrays?

@doc "dataset method for SEXP{INTSXP} must check if the argument is a factor"->
function dataset(s::SEXP{INTSXP})
    isFactor(s) || return DataArray(s)
    ## refs array uses a zero index where R has a missing value, R_NaInt
    refs = DataArrays.RefArray(map!(x -> x == R_NaInt ? zero(Int32) : x,vec(s)))
    compact(PooledDataArray(refs,R.levels(s)))
end

Base.names(s::SEXP) = vec(sexp(ccall((:Rf_getAttrib,libR),Ptr{Void},
                                       (Ptr{Void},Ptr{Void}),s,namesSymbol)))

function dataset(s::SEXP{VECSXP})
    val = [dataset(v) for v in s]
    R.inherits(s,"data.frame") ? DataFrame(val,Symbol[symbol(nm) for nm in names(s)]) : val
end

dataset(st::ASCIIString) = dataset(reval(rparse(st)))

@doc "Evaluate Symbol s as an R dataset"->
dataset(s::Symbol) = dataset(reval(s))

@doc "extract the value of symbol s in the environment e"->
Base.getindex(e::SEXP{ENVSXP},s::Symbol) =
    sexp(ccall((:Rf_findVarInFrame,libR),Ptr{Void},(Ptr{Void},Ptr{Void}),e,sexp(s)))

@doc "assign value v to symbol s in the environment e"->
Base.setindex!(e::SEXP{ENVSXP},v::SEXP,s::Symbol) =
    ccall((:Rf_setVar,libR),Void,(Ptr{Void},Ptr{Void},Ptr{Void}),sexp(s),v,e)
Base.setindex!{T<:Number}(e::SEXP{ENVSXP},v::Array{T},s::Symbol) = setindex!(e,sexp(v),s)
Base.setindex!(e::SEXP{ENVSXP},v::Number,s::Symbol) = setindex!(e,sexp(v),s)
Base.setindex!(e::SEXP{ENVSXP},v::Real,s::Symbol) = setindex!(e,sexp(v),s)

function preserve(s::SEXP)
    ccall((:R_PreserveObject,libR),Void,(Ptr{Void},),s)
    finalizer(s,x -> ccall((:R_ReleaseObject,libR),Void,(Ptr{Void},),x))
    s
end

function sexp(v::BitVector)             # handled separately
    l = length(v)
    vv = sexp(ccall((:Rf_allocVector,libR),Ptr{Void},(Cint,Cptrdiff_t),LGLSXP,l))
    copy!(pointer_to_array(convert(Ptr{Int32},vv.p+voffset),l),v)
    preserve(vv)
end

for (typ,rnm,tag,rtyp) in ((:Bool,:Logical,LGLSXP,:Int32),
                           (:Complex128,:Complex,CPLXSXP,:Complex128),
                           (:Integer,:Integer,INTSXP,:Int32),
                           (:Real,:Real,REALSXP,:Float64))
    @eval begin
        function sexp(v::$typ)
            preserve(sexp(ccall(($(string("Rf_Scalar",rnm)),libR),Ptr{Void},($rtyp,),v)))
        end
        function sexp{T<:$typ}(v::Vector{T})
            l = length(v)
            vv = sexp(ccall((:Rf_allocVector,libR),Ptr{Void},(Cint,Cptrdiff_t),$tag,l))
            copy!(pointer_to_array(convert(Ptr{$rtyp},vv.p+voffset),l),v)
            preserve(vv)
        end
        function sexp{T<:$typ}(m::Matrix{T})
            p,q = size(m)
            vv = sexp(ccall((:Rf_allocMatrix,libR),Ptr{Void},(Cint,Cint,Cint),$tag,p,q))
            copy!(pointer_to_array(convert(Ptr{$rtyp},vv.p+voffset),l),m)
            preserve(vv)
        end
        function sexp{T<:$typ}(a::Array{T,3})
            p,q,r = size(a)
            vv = sexp(ccall((:Rf_alloc3DArray,libR),Ptr{Void},(Cint,Cint,Cint,Cint),$tag,p,q,r))
            copy!(pointer_to_array(convert(Ptr{$rtyp},vv.p+voffset),l),a)
            preserve(vv)
        end
        function sexp{T<:$typ}(a::Array{T})
            rdims = sexp([size(a)...])
            vv = sexp(ccall((:Rf_allocArray,libR),Ptr{Void},(Cint,Ptr{Void}),$tag,rdims))
            copy!(pointer_to_array(convert(Ptr{$rtyp},vv.p+voffset),l),a)
            preserve(vv)
        end
    end
end

sexp(s::Symbol) = sexp(ccall((:Rf_install,libR),Ptr{Void},(Ptr{Uint8},),string(s)))
sexp(st::Union(ASCIIString,UTF8String)) = sexp(ccall((:Rf_mkString,libR),Ptr{Void},(Ptr{Uint8},),st))
