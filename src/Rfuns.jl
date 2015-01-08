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
class(s::SEXP) = vec(Reval(lang2(RCall.classSymbol,s)))

@doc "Check S3 inheritance (I think only S3)"->
inherits(s::SEXP,cls::ASCIIString) =
    ccall((:Rf_inherits,libR),Bool,(Ptr{Void},Ptr{Uint8}),s.p,cls)

@doc "return the levels vector from a factor"->
levels(s::SEXP{13}) = vec(Reval(lang2(RCall.levelsSymbol,s)))

@doc "attach an R package"->
library(sym::Symbol) = Reval(lang2(install(:library),install(sym)))

@doc "examine the structure of an R object"->
str(s::SEXP) = Reval(lang2(install(:str),s))
str(s::Symbol) = Reval(lang2(install(:str),install(s)))

@doc "list the objects in the global environment or in a package that is already attached"->
ls(;printR::Bool=true) = (v = Reval(lang1(install(:ls))); printR ? Rprint(v) : v)
function ls(pkg::ASCIIString;printR::Bool=true)
    v = Reval(lang2(install(:ls),mkString(string("package:",pkg))))
    printR ? Rprint(v) : v
end

end
