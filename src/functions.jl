"Create a function call from a list of arguments"
function rlang_p(f, args...; kwargs...)
    argn = length(args)+length(kwargs)
    s = l = protect(allocArray(LangSxp,argn+1))
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

"Create a function call from a function pointer and a list of arguments and return it as an RObject, which can then be evaulated"
rlang(f, args...; kwargs...) = RObject(rlang_p(f,args...; kwargs...))

"""
Evaluate a function in the global environment. The first argument corresponds
to the function to be called. It can be either a FunctionSxp type, a SymSxp or
a Symbol."""
rcall(f,args...;kwargs...) = reval(rlang_p(f,args...;kwargs...))
rcall_p(f,args...;kwargs...) = reval_p(rlang_p(f,args...;kwargs...))

if VERSION >= v"v0.4-"
    @compat Base.call{S<:Union{SymSxp,LangSxp,FunctionSxp}}(f::RObject{S},args...;kwargs...) = rcall(f,args...;kwargs...)
end

"""
Returns a variable named "str". Useful for passing keyword arguments containing dots.
"""
macro var_str(str)
    esc(symbol(str))
end
