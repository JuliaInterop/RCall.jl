module R

using ..RCall

export
    class,
    inherits,
    levels,
    library,
    str

@doc "Query the class of an SEXP (should work for S3 and S4)"->
class(s::SEXP) = RCall.rawvector(Reval(lang2(RCall.classSymbol,s)))

@doc "Check for S3 inheritance (I think only S3)"->
inherits(s::SEXP,cls::ASCIIString) =
    ccall((:Rf_inherits,libR),Bool,(Ptr{Void},Ptr{Uint8}),s.p,cls)

@doc "return the levels vector from a factor"->
levels(s::SEXP{13}) = RCall.rawvector(Reval(lang2(RCall.levelsSymbol,s)))

@doc "attach an R package"->
library(sym::Symbol) = Reval(lang2(install(:library),install(sym)))

@doc "examine the structure of an R object"->
str(s::SEXP) = Reval(lang2(install(:str),s))
str(s::Symbol) = Reval(lang2(install(:str),install(s)))

end
