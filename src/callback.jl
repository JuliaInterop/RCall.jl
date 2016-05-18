"""
Register a function pointer as an R NativeSymbol.

This is completely undocumented, so may break: we technically are supposed to
use R_registerRoutines, but this is _much_ easier for just 1 function.
"""
function makeNativeSymbol(fptr::Ptr{Void})
    # Rdynpriv.h
    rexfn = ccall((:R_MakeExternalPtrFn,libR), ExtPtrSxpPtr,
                     (Ptr{Void}, Ptr{Void}, Ptr{Void}),
                     fptr, sexp(Symbol("native symbol")), sexp(Const.NilValue))
    setAttrib!(rexfn, Const.ClassSymbol, sexp("NativeSymbol"))
    preserve(rexfn)
    rexfn
end


"Create an ExtPtrSxpPtr object"
makeExternalPtr(ptr::Ptr{Void}, tag=Const.NilValue, prot=Const.NilValue) =
    ccall((:R_MakeExternalPtr,libR), ExtPtrSxpPtr,
          (Ptr{Void}, UnknownSxpPtr, UnknownSxpPtr),
          ptr, sexp(tag), sexp(prot))


"""
The function called by R .External for Julia callbacks.

It receives a `ListSxpPtr` containing
 - a pointer to the function itself (`ExtPtrSxpPtr`)
 - a pointer to the Julia function (`ExtPtrSxpPtr`)
 - any arguments (as `SxpPtr`)
"""
function callJuliaExtPtr(p::ListSxpPtr)
    try
        l = cdr(p) # skip callback pointer

        # julia function pointer
        f_sxp = car(l)::ExtPtrSxpPtr
        f_sxprec = unsafe_load(f_sxp)
        f = unsafe_pointer_to_objref(f_sxprec.ptr)
        l = cdr(l)

        # # extract arguments
        args = Any[]
        kwargs = Any[]
        for (k,a) in l
            # TODO: provide a mechanism for users to specify their own
            # conversion routines
            if k == sexp(Const.NilValue)
                push!(args,rcopy(a))
            else
                push!(kwargs,(rcopy(Symbol,k),rcopy(a)))
            end
        end

        # call function
        y = f(args...;kwargs...)

        # return appropriate sexp
        return p = convert(UnknownSxpPtr,sexp(y))::UnknownSxpPtr
    catch e
        ccall((:Rf_error,libR),Ptr{Void},(Ptr{Cchar},),string(e))
        return convert(UnknownSxpPtr,sexp(Const.NilValue))::UnknownSxpPtr
    end
end


"""
Julia types (typically functions) which are wrapped in `ExtPtrSxpPtr` are
stored here to prevent garbage collection by Julia.
"""
const jtypExtPtrs = Dict{ExtPtrSxpPtr, Any}()

"""
Called by the R finalizer.
"""
function decrefExtPtr(p::ExtPtrSxpPtr)
    delete!(jtypExtPtrs, p)
    return nothing
end

const juliaDecref = Ref{Ptr{Void}}()

"""
Register finalizer to be called by the R GC.
"""
function registerFinalizer(s::ExtPtrSxpPtr)
    ccall((:R_RegisterCFinalizerEx,libR),Void,
          (Ptr{ExtPtrSxp}, Ptr{Void}, Cint),
          s,juliaDecref[],0)
end


sexp(::Type{ExtPtrSxp}, s::Ptr{ExtPtrSxp}) = s
sexp(::Type{ExtPtrSxp}, r::RObject{ExtPtrSxp}) = sexp(r)
sexp(::Type{ClosSxp}, s::Ptr{ClosSxp}) = s
sexp(::Type{ClosSxp}, r::RObject{ClosSxp}) = sexp(r)

"""
Wrap a Julia object an a R `ExtPtrSxpPtr`.

We store the pointer and the object in a const Dict to prevent it being
removed by the Julia GC.
"""
function sexp(::Type{ExtPtrSxp}, j)
    jptr = pointer_from_objref(j)
    s = makeExternalPtr(jptr)
    jtypExtPtrs[s] = j
    registerFinalizer(s)
    s
end

const juliaCallback = RObject{ExtPtrSxp}()

"""
Wrap a callable Julia object `f` an a R `ClosSxpPtr`.

Constructs the following R code

    function(...) .External(juliaCallback, fExPtr, ...)

"""
function sexp(::Type{ClosSxp}, f)
    body = protect(rlang_p(Symbol(".External"),
                           juliaCallback,
                           sexp(ExtPtrSxp,f),
                           Const.DotsSymbol))
    local clos
    try
        lang = rlang_p(:function, sexp_arglist_dots(), body)
        clos = reval_p(lang)
    finally
        unprotect(1)
    end
    clos
end

"""
Create an argument list for an R function call, with a varargs "dots" at the end.
"""
function sexp_arglist_dots(args...;kwargs...)
    rarglist = protect(allocList(length(args)+length(kwargs)+1))
    try
        rr = rarglist
        for var in args
            settag!(rr, sexp(var))
            setcar!(rr, Const.MissingArg)
            rr = cdr(rr)
        end
        for (var,val) in kwargs
            settag!(rr, sexp(var))
            setcar!(rr, sexp(val))
            rr = cdr(rr)
        end
        settag!(rr, Const.DotsSymbol)
        setcar!(rr, Const.MissingArg)
    finally
        unprotect(1)
    end
    rarglist
end

sexp(f::Function) = sexp(ClosSxp, f)
