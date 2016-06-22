"Create a function call from a list of arguments"
function rlang_p(f, args...; kwargs...)
    argn = length(args)+length(kwargs)
    s = l = protect(allocArray(LangSxp,argn+1))
    try
        setcar!(s,sexp(f))
        for argv in args
            s = cdr(s)
            setcar!(s,sexp(argv))
        end
        for (key,argv) in kwargs
            s = cdr(s)
            settag!(s,sexp(key))
            setcar!(s,sexp(argv))
        end
    finally
        unprotect(1)
    end
    l
end

"Create a function call from a function pointer and a list of arguments and return it as an RObject, which can then be evaulated"
rlang(f, args...; kwargs...) = RObject(rlang_p(f,args...; kwargs...))

"""
Evaluate a function in the global environment. The first argument corresponds
to the function to be called. It can be either a FunctionSxp type, a SymSxp or
a Symbol."""
rcall(f,args...;kwargs...) = reval(rlang_p(f,args...;kwargs...))
rcall_p(f,args...;kwargs...) = reval_p(rlang_p(f,args...;kwargs...))

@compat (f::RObject{S}){S<:Union{SymSxp,LangSxp,PromSxp,FunctionSxp}}(args...;kwargs...) = rcall(f,args...;kwargs...)
