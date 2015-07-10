@doc "Create a function call from a list of arguments"->
function rlang_p(f, args...; kwargs...)
    argn = length(args)+length(kwargs)
    s = l = protect(allocArray(LangSxpRec,argn+1))
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
    unprotect(1)
    l
end

rlang(f, args...; kwargs...) = RObject(rlang_p(f,args...; kwargs...))

@doc """
Evaluate a function in the global environment. The first argument corresponds
to the function to be called. It can be either a FunctionSxpRec type, a SymSxpRec or
a Symbol."""->
rcall(f,args...;kwargs...) = reval(rlang_p(f,args...;kwargs...))

if VERSION >= v"v0.4-"
    Base.call{S<:Union(SymSxpRec,LangSxpRec,FunctionSxpRec)}(f::RObject{S},args...;kwargs...) = rcall(f,args...;kwargs...)
end
