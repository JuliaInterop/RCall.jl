@doc "Create a function call from a vector of the arguments"->
function lang(f::SEXPREC,args...;kwargs...)
    argn = length(args)+length(kwargs)
    l = preserve(sexp(ccall((:Rf_allocVector,libR),Ptr{Void},(Cint,Int),6,argn+1)))
    s = l.p
    ccall((:SETCAR,libR),Ptr{Void},(Ptr{Void},Ptr{Void}),s,f)
    for argv in args
        typeof(argv) <: SEXPREC || throw(MethodError())
        s = ccall((:CDR,libR),Ptr{Void},(Ptr{Void},),s)
        ccall((:SETCAR,libR),Ptr{Void},(Ptr{Void},Ptr{Void}),s,argv)
    end
    for (key,argv) in kwargs
        typeof(argv) <: SEXPREC || throw(MethodError())
        s = ccall((:CDR,libR),Ptr{Void},(Ptr{Void},),s)
        ccall((:SET_TAG,libR),Ptr{Void},(Ptr{Void},Ptr{Void}),s,sexp(key))
        ccall((:SETCAR,libR),Ptr{Void},(Ptr{Void},Ptr{Void}),s,argv)
    end
    l
end

@doc "Evaluate the function in the global environment"->
rcall(f::Union(SymSxp,RFunction),args...;kwargs...) = reval(lang(f,args...,kwargs...))
rcall(f::Symbol,args...;kwargs...) = rcall(sexp(f),args...,kwargs...)
