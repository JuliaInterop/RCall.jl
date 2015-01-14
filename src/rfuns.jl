module R

using ..RCall
if VERSION < v"0.4-"
    using Docile   # I thought this would be propagated from RCall but apparently not.
end

export
    class,
    inherits,
    levels,
    library,
    ls,
    str

@doc "Query the class of an SEXP (should work for S3 and S4)"->
class(s::SEXP) = vec(reval(lang2(RCall.classSymbol,s)))

@doc "Check S3 inheritance (I think only S3)"->
inherits(s::SEXP,cls::ASCIIString) =
    ccall((:Rf_inherits,libR),Bool,(Ptr{Void},Ptr{Uint8}),s,cls)

@doc "return the levels vector from a factor"->
levels(s::SEXP{RCall.INTSXP}) = vec(reval(lang2(RCall.levelsSymbol,s)))

@doc "attach an R package"->
library(sym::Symbol) = reval(lang2(sexp(:library),sexp(sym)))

@doc "list the objects in the global environment or in a package that is already attached"->
ls(;printR::Bool=true) = (v = reval(lang1(sexp(:ls))); printR ? rprint(v) : v)
function ls(pkg::ASCIIString;printR::Bool=true)
    v = reval(lang2(sexp(:ls),sexp(string("package:",pkg))))
    printR ? rprint(v) : v
end

@doc "examine the structure of an R object"->
str(s::SEXP) = reval(lang2(sexp(:str),s))
str(s::Symbol) = str(sexp(s))

end
