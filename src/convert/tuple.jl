function sexp(::Type{RClass{:JuliaTuple}}, t::Tuple)
    vs = sexp(RClass{:list}, t)
    # mark this as originating from a tuple
    # for roundtrippping, which downstream JuliaCall
    # relies on
    # because of the way S3 classes work, this doesn't break anything on the R side
    # and strictly adds more information that we can take advantage of
    setattrib!(vs, :class, sexp("JuliaTuple"))
    vs
end

function sexp(::Type{RClass{:list}}, t::Tuple)
    n = length(t)
    vs = protect(allocArray(VecSxp,n))
    try
        for (i, v) in enumerate(t)
            vs[i] = v
        end
    finally
        unprotect(1)
    end
    vs
end

sexpclass(::Tuple) = RClass{:JuliaTuple}  

rcopytype(::Type{RClass{:JuliaTuple}}, x::Ptr{VecSxp}) = Tuple

function rcopy(::Type{T}, s::Ptr{VecSxp}) where {T <: Tuple}
    protect(s)
    try
        T(rcopy(el) for el in s)
    finally
        unprotect(1)
    end
end
