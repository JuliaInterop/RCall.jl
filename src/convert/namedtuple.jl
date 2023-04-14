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

sexpclass(::NamedTuple) = RClass{:list}

function rcopy(::Type{NamedTuple}, s::Ptr{VecSxp})
    protect(s)
    try
        names = Symbol[]
        vals = Any[]

        for k in rcopy(Array{Symbol}, getnames(s))
            push!(names, k)
            push!(vals, rcopy(s[k]))
        end

        NamedTuple{(names...,)}(vals)
    finally
        unprotect(1)
    end
end

function rcopy(::Type{NamedTuple{names}}, s::Ptr{VecSxp}) where names
    protect(s)
    try
        vals = Any[]
        n = rcopy(Array{Symbol}, getnames(s))
        if length(intersect(n, names)) != length(names)
            throw(ArgumentError("cannot convert to NamedTuple: wrong names"))
        end

        vals = rcopy(Array, s)
        NamedTuple{names}(vals)
    finally
        unprotect(1)
    end
end

function rcopy(::Type{NamedTuple{names, types}}, s::Ptr{VecSxp}) where {names, types}
    protect(s)
    try
        vals = Any[]
        n = rcopy(Array{Symbol}, getnames(s))
        if length(intersect(n, names)) != length(names)
            throw(ArgumentError("cannot convert to NamedTuple: wrong names"))
        end

        vals = rcopy(Array, s)
        NamedTuple{names, types}(vals)
    finally
        unprotect(1)
    end
end
