## a list of reserved names from PyCall.jl
const reserved = Set{String}([
    "while", "if", "for", "try", "return", "break", "continue",
    "function", "macro", "quote", "let", "local", "global", "const",
    "abstract", "typealias", "type", "bitstype", "immutable", "ccall",
    "do", "module", "baremodule", "using", "import", "export", "importall",
    "false", "true", "Tuple", "rmember", "__package__"])


const cached_namespaces = Dict{String, Module}()

"""
Import an R package as a julia module.
Sanitizes the imported symbols by default, because otherwise certain symbols cannot be used.

E.g.: `PerformanceAnalytics::charts.Bar` in R becomes `PerformanceAnalytics.charts_Bar` in Julia
```
gg = rimport("ggplot2")
```

`normalization` is passed directly to `replace` via splatting.
"""
function rimport(pkg::String, s::Symbol=gensym(:rimport);
                 normalizenames::Bool=true, normalization=['.' => '_'])
    if pkg in keys(cached_namespaces)
        m = cached_namespaces[pkg]
    else
        ns = rcall(:asNamespace, pkg)
        # XXX note that R is sensitive to definition order, so do not change the order!
        members = rcopy(Vector{String}, rcall(:getNamespaceExports, ns))

        m = Module(s, false)
        id = Expr(:const, Expr(:(=), :__package__, pkg))
        if normalizenames
            exports = [Symbol(replace(x, normalization...)) for x in members]
            dupes = [k for (k, v) in countmap(exports) if v > 1]
            if !isempty(dupes)
                error("Normalized names are no longer unique: " *
                       join(dupes, ", ", " and "))
            end
        else
            exports = [Symbol(x) for x in members]
        end

        filtered_indices = filter!(i -> !(string(exports[i]) in reserved),
                                   collect(eachindex(exports)))
        consts = [Expr(:const, Expr(:(=),
                       exports[i],
                       rcall(Symbol("::"), pkg, members[i]))) for i in filtered_indices]
        Core.eval(m, Expr(:toplevel, id, consts..., Expr(:export, exports...), :(rmember(x) = ($getindex)($ns, x))))
        cached_namespaces[pkg] = m
    end
    return m
end
rimport(pkg::Symbol, args...; kwargs...) = rimport(string(pkg), args...; kwargs...)

function countmap(v::Vector{T}) where {T}
    occurrences = Dict{Symbol,Int}()
    for el in v
        occurrences[el] = get(occurrences, el, 0) + 1
    end
    return occurrences
end

"""
Import an R Package as a Julia module. For example,
```
@rimport ggplot2
```
is equivalent to `ggplot2 = rimport("ggplot2")` with error checking.

You can also use classic Python syntax to make an alias: `@rimport *package-name* as *shorthand*`
```
@rimport ggplot2 as gg
```
which is equivalent to `gg = rimport("ggplot2")`.
"""
macro rimport(x, args...)
    if length(args)==2 && args[1] == :as
        m = Symbol(args[2])
    elseif length(args)==0
        m = Symbol(x)
    else
        throw(ArgumentError("invalid import syntax."))
    end
    pkg = string(x)
    quote
        if !isdefined(@__MODULE__, $(QuoteNode(m)))
            const $(esc(m)) = rimport($pkg)
            nothing
        elseif typeof($(esc(m))) <: Module &&
                    :__package__ in names($(esc(m)), all = true) &&
                    $(esc(m)).__package__ == $pkg
            nothing
        else
            error($pkg * " already exists! Use the syntax `@rimport " * $pkg *" as *shorthand*`.")
            nothing
        end
    end
end

"""
Load all exported functions/objects of an R package to the current module. Almost equivalent to
```
__temp__ = rimport("ggplot2")
using .__temp__
```
"""
macro rlibrary(x)
    m = gensym("RCall")
    quote
        $(esc(m)) = rimport($(QuoteNode(x)))
        Core.eval(@__MODULE__, Expr(:using, Expr(:., :., $(QuoteNode(m)))))
    end
end
