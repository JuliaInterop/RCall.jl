## a list of reserved names from PyCall.jl
const reserved = Set{String}([
    "while", "if", "for", "try", "return", "break", "continue",
    "function", "macro", "quote", "let", "local", "global", "const",
    "abstract", "typealias", "type", "bitstype", "immutable", "ccall",
    "do", "module", "baremodule", "using", "import", "export", "importall",
    "false", "true", "Tuple", "rmember", "__package__"])


cached_namespaces = Dict{String, Module}()

"""
Import an R package as a julia module.
```
gg = rimport("ggplot2")
```
"""
function rimport(pkg::String, s::Symbol=:__anonymous__)
    if pkg in keys(cached_namespaces)
        m = cached_namespaces[pkg]
    else
        ns = rcall(:asNamespace, pkg)
        members = rcopy(Vector{String}, rcall(:getNamespaceExports, ns))
        filter!(x -> !(x in reserved), members)
        m = Module(s, false)
        id = Expr(:const, Expr(:(=), :__package__, pkg))
        consts = [Expr(:const, Expr(:(=),
                       Symbol(x),
                       rcall(Symbol("::"), pkg, x))) for x in members]
        exports = [Symbol(x) for x in members]
        eval(m, Expr(:toplevel, id, consts..., Expr(:export, exports...), :(rmember(x) = ($getindex)($ns, x))))
        cached_namespaces[pkg] = m
    end
    m
end
rimport(pkg::Symbol, s::Symbol=:__anonymous__) = rimport(string(pkg), s)

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
        if !isdefined($(QuoteNode(m)))
            const $(esc(m)) = rimport($pkg)
            nothing
        elseif typeof($(esc(m))) <: Module &&
                    :__package__ in names($(esc(m)), true) &&
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
        eval(current_module(), Expr(:using, :., $(QuoteNode(m))))
    end
end
