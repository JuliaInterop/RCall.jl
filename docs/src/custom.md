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
nothing
```

## Julia to R direction

The function [`RCall.sexp`](@ref) has to be overwritten to allow Julia to R
conversion. `sexp` function takes a julia object and returns an SEXP object
(pointer to [`Sxp`]).

```@example 2
import RCall.sexp

function sexp(f::Foo)
    r = sexp(Dict(:x => f.x, :y => f.y))
    setclass!(r, sexp("Bar"))
    r
end

roo = RObject(foo)
```

Remark: [`RCall.protect`](@ref) and [`RCall.unprotect`](@ref) should be used to protect SEXP from being garbage collected.

## R to Julia direction

The function `rcopy` and `rcopytype` are responsible for conversions of this direction.


```@example 2
# first we define a explicit convertor for VecSxp (SEXP for list)

import RCall.rcopy

function rcopy(::Type{Foo}, s::Ptr{VecSxp})
    Foo(rcopy(Float64, s[:x]), rcopy(String, s[:y]))
end
```

The `convert` function will dispatch the corresponding `rcopy` function when it is found.

```@example 2
rcopy(Foo, roo)
convert(Foo, roo)
nothing
```

To allow the automatic conversion via `rcopy(roo)`, the R class `Bar` has to be registered.

```@example 2
import RCall: RClass, rcopytype

rcopytype(::Type{RClass{:Bar}}, s::Ptr{VecSxp}) = Foo

boo = rcopy(roo)
nothing
```

