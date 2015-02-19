## Methods related to the SEXP (pointer to SEXPREC type) in R

# SEXP methods for generics defined in the Base module
Base.length(s::SEXP) = ccall((:Rf_length,libR),Int,(Ptr{Void},),s)

Base.names(s::SEXP) = contents(getAttrib(s,namesSymbol))

function Base.size(s::SEXP)
    isArray(s) || return (length(s),)
    tuple(convert(Vector{Int},contents(getAttrib(s,dimSymbol)))...)
end

## Element extraction and iterators
for (N,fnm) in ((STRSXP,"STRING_ELT"),(VECSXP,"VECTOR_ELT"),(EXPRSXP,"VECTOR_ELT"))
    @eval begin
        function Base.getindex(s::SEXP{$N},I::Number)  # extract a single element
            0 < I ≤ length(s) || throw(BoundsError())
            sexp(ccall(($fnm,libR),Ptr{Void},(Ptr{Void},Cint),s,I-1))
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

## contents of a STRSXP _does_ copy the contents
contents(s::SEXP{STRSXP}) = [bytestring(ss) for ss in s]
## `contents` methods for vectors of bitstypes
for (N,rtyp,rf) in ((CPLXSXP,:Complex128,"COMPLEX"),
                    (INTSXP,:Int32,"INTEGER"),
                    (LGLSXP,:Int32,"LOGICAL"),
                    (REALSXP,:Float64,"REAL"))
    @eval contents(s::SEXP{$N}) = pointer_to_array(ccall(($rf,libR),Ptr{$rtyp},(Ptr{Void},),s),size(s))
end

## DataArray for an LGLSXP converts from Cint to Bool
function DataArrays.DataArray(s::SEXP{LGLSXP})
    src = contents(s)
    DataArray(convert(Array{Bool},src), src .== R_NaInt)
end

for N in [INTSXP,REALSXP,CPLXSXP,STRSXP]
    @eval DataArrays.DataArray(s::SEXP{$N}) = (rv = copy(contents(s)); DataArray(rv,isNA(rv)))
end

for N in [LGLSXP,REALSXP,CPLXSXP,STRSXP]
    @eval dataset(s::SEXP{$N}) = DataArray(s)
end

## the dataset method for INTSXP must check for factors.
@doc "dataset method for SEXP{INTSXP} must check if the argument is a factor"->
function dataset(s::SEXP{INTSXP})
    isFactor(s) || return DataArray(s)
    ## refs array uses a zero index where R has a missing value, R_NaInt
    refs = DataArrays.RefArray(map!(x -> x == R_NaInt ? zero(Int32) : x,copy(contents(s))))
    compact(PooledDataArray(refs,copy(contents(getAttrib(s,levelsSymbol)))))
end

function dataset(s::SEXP{VECSXP})
    val = [dataset(v) for v in s]
    isFrame(s) ? DataFrame(val,Symbol[symbol(nm) for nm in names(s)]) : val
end

dataset(st::ASCIIString) = dataset(reval(rparse(st)))

@doc "Evaluate Symbol s as an R dataset"->
dataset(s::Symbol) = dataset(reval(s))

@doc "extract the value of symbol s in the environment e"->
Base.getindex(e::SEXP{ENVSXP},s::Symbol) =
    sexp(ccall((:Rf_findVarInFrame,libR),Ptr{Void},(Ptr{Void},Ptr{Void}),e,sexp(s)))

@doc "assign value v to symbol s in the environment e"->
Base.setindex!(e::SEXP{ENVSXP},v::SEXP,s::Symbol) =
    # This should be done more carefully.  First check for the symbol in the frame.  If it is
    # defined call Rf_setVar, otherwise call Rf_defineVar.  As it stands this segfaults if
    # the symbol is bound in, say, the base environment.
    ccall((:Rf_setVar,libR),Void,(Ptr{Void},Ptr{Void},Ptr{Void}),sexp(s),v,e)
Base.setindex!(e::SEXP{ENVSXP},v,s::Symbol) = setindex!(e,sexp(v),s)

function preserve(s::SEXP)
    ccall((:R_PreserveObject,libR),Void,(Ptr{Void},),s)
    finalizer(s,x -> ccall((:R_ReleaseObject,libR),Void,(Ptr{Void},),x))
    s
end


for (typ,N,rtyp,rf,rsnm) in ((:Bool, LGLSXP, :Int32, "LOGICAL", :Logical),
                             (:Complex, CPLXSXP, :Complex128, "COMPLEX",:Complex),
                             (:Integer, INTSXP, :Int32, "INTEGER", :Integer),
                             (:Real, REALSXP, :Float64, "REAL", :Real))
    @eval sexp(v::$typ) = preserve(sexp(ccall(($(string("Rf_Scalar",rsnm)),libR),Ptr{Void},($rtyp,),v)))
end

for (typ,tag,rtyp) in ((:Bool,LGLSXP,:Int32),
                       (:Complex,CPLXSXP,:Complex128),
                       (:Integer,INTSXP,:Int32),
                       (:Real,REALSXP,:Float64))
    @eval begin
        function sexp{T<:$typ}(v::Vector{T})
            vv = sexp(ccall((:Rf_allocVector,libR),Ptr{Void},(Cint,Int),$tag,length(v)))
            copy!(contents(vv),v)
            preserve(vv)
        end
        function sexp{T<:$typ}(m::Matrix{T})
            p,q = size(m)
            vv = sexp(ccall((:Rf_allocMatrix,libR),Ptr{Void},(Int,Cint,Cint),$tag,p,q))
            copy!(contents(vv),m)
            preserve(vv)
        end
        function sexp{T<:$typ}(a::Array{T,3})
            p,q,r = size(a)
            vv = sexp(ccall((:Rf_alloc3DArray,libR),Ptr{Void},(Cint,Cint,Cint,Cint),$tag,p,q,r))
            copy!(contents(vv),a)
            preserve(vv)
        end
        function sexp{T<:$typ}(a::Array{T})
            rdims = sexp([size(a)...])
            vv = sexp(ccall((:Rf_allocArray,libR),Ptr{Void},(Cint,Ptr{Void}),$tag,rdims))
            copy!(contents(vv),a)
            preserve(vv)
        end
    end
end


function sexp(v::BitVector)             # handled separately
    l = length(v)
    vv = sexp(ccall((:Rf_allocVector,libR),Ptr{Void},(Cint,Cptrdiff_t),LGLSXP,l))
    copy!(contents(vv),v)
    preserve(vv)
end
sexp(s::Symbol) = sexp(ccall((:Rf_install,libR),Ptr{Void},(Ptr{Uint8},),string(s)))
sexp(st::Union(ASCIIString,UTF8String)) = sexp(ccall((:Rf_mkString,libR),Ptr{Void},(Ptr{Uint8},),st))
function sexp{T<:Union(ASCIIString,UTF8String)}(v::Vector{T})
    l = length(v)
    vv = sexp(ccall((:Rf_allocVector,libR),Ptr{Void},(Cint,Cptrdiff_t),STRSXP,l))
    for i in 1:l
        ccall((:SET_STRING_ELT,libR),Void,(Ptr{Void},Cint,Ptr{Void}),
              vv,i-1,ccall((:Rf_mkChar,libR),Ptr{Void},(Ptr{Uint8},),v[i]))
    end
    preserve(vv)
end
