@doc """
Register a function pointer as an R NativeSymbol.

This is completely undocumented, so may break: we technically are supposed to
use R_registerRoutines, but this is _much_ easier for just 1 function.
""" ->
function makeNativeSymbol(fptr::Ptr{Void})
    # Rdynpriv.h
    rexfn = ccall((:R_MakeExternalPtrFn,libR), ExtPtrSxp,
                     (Ptr{Void}, Ptr{Void}, Ptr{Void}),
                     fptr, sexp(symbol("native symbol")), rNilValue)
    setAttrib!(rexfn, rClassSymbol, sexp("NativeSymbol"))
    rexfn
end


@doc "Create an ExtPtrSxp object"->
makeExternalPtr(ptr::Ptr{Void}, tag=rNilValue, prot=rNilValue) =
    ccall((:R_MakeExternalPtr,libR), ExtPtrSxp,
          (Ptr{Void}, UnknownSxp, UnknownSxp),
          ptr, tag, prot)


@doc """
The function called by R .External for Julia callbacks.

It receives a `ListSxp` containing
 - a pointer to the function itself (`ExtPtrSxp`)
 - a pointer to the Julia function (`ExtPtrSxp`)
 - any arguments (as `Sxp`)
"""->
function callJuliaExtPtr(p::ListSxp)
    try
        l = cdr(p) # skip callback pointer

        # julia function pointer
        f_sxp = car(l)::ExtPtrSxp
        f_sxprec = unsafe_load(f_sxp)
        f = unsafe_pointer_to_objref(f_sxprec.ptr)
        l = cdr(l)

        # # extract arguments
        args = Any[]
        kwargs = Any[]
        for (k,a) in l
            # TODO: provide a mechanism for users to specify their own
            # conversion routines
            if k == rNilValue
                push!(args,rcopy(a))
            else
                push!(kwargs,(rcopy(Symbol,k),rcopy(a)))
            end
        end

        # call function
        y = f(args...;kwargs...)

        # return appropriate sexp
        return p = convert(UnknownSxp,sexp(y))::UnknownSxp
    catch e
        ccall((:Rf_error,libR),Ptr{Void},(Ptr{Cchar},),string(e))
        return convert(UnknownSxp,rNilValue)::UnknownSxp
    end
end


@doc """
Julia types (typically functions) which are wrapped in `ExtPtrSxp` are
stored here to prevent garbage collection by Julia.
"""->
const jtypExtPtrs = Dict{ExtPtrSxp, Any}()

@doc """
Called by the R finalizer.
"""->
function decrefExtPtr(p::ExtPtrSxp)
    delete(jtypExtPtrs, p)
    return nothing
end


@doc """
Register finalizer to be called by the R GC.
"""->
function registerFinalizer(s::ExtPtrSxp)
    ccall((:R_RegisterCFinalizerEx,libR),Void,
          (Ptr{ExtPtrSxpRec}, Ptr{Void}, Cint),
          s,pJuliaDecref,0)
end

@doc """
Wrap a Julia object an a R `ExtPtrSxp`.

We store the pointer and the object in a const Dict to prevent it being
removed by the Julia GC.
"""->
function sexp(::Type{ExtPtrSxpRec}, j)
    jptr = pointer_from_objref(j)
    s = makeExternalPtr(jptr)
    jtypExtPtrs[s] = j
    registerFinalizer(s)
    s
end

@doc """
Wrap a callable Julia object `f` an a R `ClosSxp`.

Constructs the following R code

    function(...) .External(rJuliaCallback, fExPtr, ...)

"""->
function sexp(::Type{ClosSxpRec}, f)
    # TODO: is there a way to construct a ClosSxpRec directly?
    args = protect(allocList(1))
    setcar!(args, rMissingArg)
    settag!(args, rDotsSymbol)

    body = protect(rlang_p(symbol(".External"),
                           rJuliaCallback,
                           sexp(ExtPtrSxpRec,f),
                           rDotsSymbol))

    lang = rlang_p(:function, args, body)
    clos = reval_p(lang)
    unprotect(2)
    clos
end

sexp(f::Function) = sexp(ClosSxpRec, f)
