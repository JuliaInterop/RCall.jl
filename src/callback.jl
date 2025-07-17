"""
    makeNativeSymbolRef(fptr::Ptr{Cvoid})

Register a function pointer as an R `NativeSymbol`.

"""
function makeNativeSymbolRef(fptr::Ptr{Cvoid})
    # mirror Rf_MakeNativeSymbolRef of Rdynload.c
    rexfn = ccall((:R_MakeExternalPtrFn,libR), Ptr{ExtPtrSxp},
                     (Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
                     fptr, sexp(Symbol("native symbol")), sexp(Const.NilValue))
    setattrib!(rexfn, Const.ClassSymbol, "NativeSymbol")
    preserve(rexfn)
    rexfn
end


"""
    makeExternalPtr(ptr::Ptr{Cvoid},
                    tag=Const.NilValue,
                    prot=Const.NilValue)

Create an Ptr{ExtPtrSxp} object.
"""
function makeExternalPtr(ptr::Ptr{Cvoid}, tag=Const.NilValue, prot=Const.NilValue)
    return ccall((:R_MakeExternalPtr,libR), Ptr{ExtPtrSxp},
                 (Ptr{Cvoid}, Ptr{UnknownSxp}, Ptr{UnknownSxp}),
                 ptr, sexp(tag), sexp(prot))
end

"""
    julia_extptr_callback(p::Ptr{ListSxp})

The function called by R `.External` for Julia callbacks.

The argument should be a `Ptr{ListSxp}` containing
 - a pointer to the function itself (`Ptr{ExtPtrSxp}`)
 - a pointer to the Julia function (`Ptr{ExtPtrSxp}`)
 - any arguments (as `Ptr{S<:Sxp}`)

Returns `Ptr{UnknownSxp}` to the result.
"""
function julia_extptr_callback(p::Ptr{ListSxp})
    protect(p)
    try
        l = cdr(p) # skip callback pointer

        # julia function pointer
        f_sxp = car(l)::Ptr{ExtPtrSxp}
        ptr = ccall((:R_ExternalPtrAddr, libR), Ptr{Cvoid}, (Ptr{ExtPtrSxp},), f_sxp)
        f = unsafe_pointer_to_objref(ptr)[]
        l = cdr(l)

        # # extract arguments
        args = Any[]
        kwargs = Any[]
        for (k,a) in pairs(l)
            # TODO: provide a mechanism for users to specify their own
            # conversion routines
            if k == sexp(Const.NilValue)
                push!(args, rcopy(a))
            else
                push!(kwargs, (rcopy(Symbol,k), rcopy(a)))
            end
        end
        # call function
        y = f(args...;kwargs...)

        # return appropriate sexp
        return p = convert(Ptr{UnknownSxp}, sexp(y))::Ptr{UnknownSxp}
    catch e
        err = rcall(reval("base::simpleError"), string(e))
        return convert(Ptr{UnknownSxp}, sexp(err))::Ptr{UnknownSxp}
    finally
        unprotect(1)
    end
end


"""
    JULIA_TYPES_EXT_PTRS

Julia types (typically functions) which are wrapped in `Ptr{ExtPtrSxp}` are
stored here to prevent garbage collection by Julia.
"""
const JULIA_TYPES_EXT_PTRS = Dict{Ptr{ExtPtrSxp}, Any}()

"""
    jtypExtPtrs

Deprecated alias for [`JULIA_TYPES_EXT_PTRS`](@ref)
"""
const jtypExtPtrs = JULIA_TYPES_EXT_PTRS

"""
    decref_extptr(p::Ptr{ExtPtrSxp})

Called by the R finalizer to remove `p` from [`JULIA_TYPES_EXT_PTRS`](@ref)
"""
function decref_extptr(p::Ptr{ExtPtrSxp})
    delete!(JULIA_TYPES_EXT_PTRS, p)
    return nothing
end

"""
    registerCFinalizerEx(s::Ptr{ExtPtrSxp})

Register finalizer to be called by the R GC.
"""
function registerCFinalizerEx(s::Ptr{ExtPtrSxp})
    protect(s)
    decref_extptr_ptr = @cfunction(decref_extptr,Nothing,(Ptr{ExtPtrSxp},))
    ccall((:R_RegisterCFinalizerEx,libR),Nothing,
          (Ptr{ExtPtrSxp}, Ptr{Cvoid}, Cint),
          s,decref_extptr_ptr,0)
    unprotect(1)
    return nothing
end


"""
    JULIA_CALLBACK

`RObject` containing an `ExtPtrSxp` to the Julia callback.
"""
const JULIA_CALLBACK = RObject{ExtPtrSxp}()


"""
    setup_callbacks()

Initialize [`JULIA_CALLBACK`](@ref)
"""
function setup_callbacks()
    julia_extptr_callback_ptr = @cfunction(julia_extptr_callback,Ptr{UnknownSxp},(Ptr{ListSxp},))
    JULIA_CALLBACK.p = makeNativeSymbolRef(julia_extptr_callback_ptr)
    return nothing
end


"""
    sexp(::Type{RClass{:externalptr}}, j::Any)

Wrap a Julia object in a R `Ptr{ExtPtrSxp}`.

We store the pointer and the object in `JULIA_TYPES_EXT_PTRS` to protect it
from Julia's GC.
"""
function sexp(::Type{RClass{:externalptr}}, j)
    # wrap in a `Ref`
    refj = Ref(j)
    jptr = pointer_from_objref(refj)
    s = makeExternalPtr(jptr)
    JULIA_TYPES_EXT_PTRS[s] = refj
    registerCFinalizerEx(s)
    s
end

"""
    sexp(::Type{RClass{:function}}, f)

Wrap a callable Julia object `f` in a R `ClosSxpPtr`.

Constructs the following R code

    function(...) .External(JULIA_CALLBACK, fExPtr, ...)

"""
function sexp(::Type{RClass{:function}}, f)
    fptr = protect(sexp(RClass{:externalptr}, f))
    body = protect(rlang_p(Symbol(".External"),
                           JULIA_CALLBACK,
                           fptr,
                           Const.DotsSymbol))
    nprotect = 2
    local clos
    try
        args = protect(sexp_arglist_dots())
        nprotect += 1
        lang = rlang_p(:function, args, body)
        clos = reval_p(lang)
    finally
        unprotect(nprotect)
    end
    clos
end


"""
    sexp_arglist_dots(args...; kwargs...)

Create an argument list for an R function call, with a varargs "dots" at the end.
"""
function sexp_arglist_dots(args...; kwargs...)
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
