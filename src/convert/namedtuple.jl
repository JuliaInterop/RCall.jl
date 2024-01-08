function sexp(::Type{RClass{:JuliaNamedTuple}}, nt::NamedTuple)
    vs = sexp(RClass{:list}, nt)
    # mark this as originating from a tuple
    # for roundtrippping, which downstream JuliaCall
    # relies on
    # because of the way S3 classes work, this doesn't break anything on the R side
    # and strictly adds more information that we can take advantage of
    setattrib!(vs, :class, sexp("JuliaNamedTuple"))
    vs
end

# keep this as a separate method to allow for conversion without the attribute
function sexp(::Type{RClass{:list}}, nt::NamedTuple)
    n = length(nt)
    vs = protect(allocArray(VecSxp,n))
    ks = protect(allocArray(StrSxp,n))
    try
        for (i,(k,v)) in enumerate(zip(keys(nt), nt))
            ks[i] = string(k)
            vs[i] = v
        end
        setnames!(vs,ks)
    finally
        unprotect(2)
    end
    vs
end

sexpclass(::NamedTuple) = RClass{:JuliaNamedTuple}

rcopytype(::Type{RClass{:JuliaNamedTuple}}, x::Ptr{VecSxp}) = NamedTuple

function rcopy(::Type{NamedTuple}, s::Ptr{VecSxp})
    protect(s)
    try 
        names = Tuple(Symbol(rcopy(n)) for n in getnames(s))
        values = rcopy(Tuple, s)
        NamedTuple{names}(values)
    finally
        unprotect(1)
    end
end

function rcopy(::Type{NamedTuple{names}}, s::Ptr{VecSxp}) where names
    protect(s)
    try
        n = Tuple(Symbol(rcopy(n)) for n in getnames(s))
        if length(intersect(n, names)) != length(names)
            throw(ArgumentError("cannot convert to NamedTuple: wrong names"))
        end

        vals = rcopy(Tuple, s)
        NamedTuple{names}(vals)
    finally
        unprotect(1)
    end
end

function rcopy(::Type{NamedTuple{names, types}}, s::Ptr{VecSxp}) where {names, types}
    protect(s)
    try
        n = Tuple(Symbol(rcopy(n)) for n in getnames(s))
        if length(intersect(n, names)) != length(names)
            throw(ArgumentError("cannot convert to NamedTuple: wrong names"))
        end

        vals = rcopy(Tuple, s)
        NamedTuple{names, types}(vals)
    finally
        unprotect(1)
    end
end
