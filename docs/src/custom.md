# Custom Conversion

RCall supports an API for implicitly converting between R and Julia objects by means of `rcopy` and `RObject`.

To illustrate the idea, we consider the following Julia type

```@setup 2
using RCall
```

```@example 2
type Foo
    x::Float64
    y::String
end
```

```@example 2
foo = Foo(1.0, "hello") 
nothing # hide
```

## Julia to R direction

The function [`RCall.sexp`](@ref) has to be overwritten to allow Julia to R
conversion. `sexp` function takes a julia object and returns an SEXP object
(pointer to [`Sxp`]).

```@example 2
import RCall.sexp

function sexp(f::Foo)
    r = protect(sexp(Dict(:x => f.x, :y => f.y)))
    setclass!(r, sexp("Bar"))
    unprotect(1)
    r
end

roo = RObject(foo)
nothing # hide
```

Remark: [`RCall.protect`](@ref) and [`RCall.unprotect`](@ref) should be used to protect SEXP from being garbage collected.

## R to Julia direction

The function `rcopy` and `rcopytype` are responsible for conversions of this
direction. First we define an explicit converter for VecSxp (SEXP for list)


```@example 2
import RCall.rcopy

function rcopy(::Type{Foo}, s::Ptr{VecSxp})
    Foo(rcopy(Float64, s[:x]), rcopy(String, s[:y]))
end
```

The `convert` function will dispatch the corresponding `rcopy` function when it is found.

```@example 2
rcopy(Foo, roo)
convert(Foo, roo) # calls `rcopy`
Foo(roo)
nothing # hide
```

To allow the automatic conversion via `rcopy(roo)`, the R class `Bar` has to be registered.

```@example 2
import RCall: RClass, rcopytype

rcopytype(::Type{RClass{:Bar}}, s::Ptr{VecSxp}) = Foo
boo = rcopy(roo)
nothing # hide
```

## Using @rput and @rget is seamless

```@example 2
boo.x = 2.0
@rput boo
R"""
boo["x"]
"""
```

```@example 2
R"""
boo["x"] = 3.0
"""
@rget boo
boo.x
```

## Nested conversion

```@example 2
l = R"list(boo = boo, roo = $roo)"
```

```@example 2
rcopy(l)
```
