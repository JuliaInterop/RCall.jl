# Getting started

The RCall package is loaded via

```@repl 1
using RCall
```

This will initialize the R process in the background.

## `R""` string macro

The simplest way to use RCall is via the [`R""`](@ref) string macro:

```@repl 1
R"rnorm(10)"
```

This evaluates the expression inside the string in R, and returns the result as an [`RObject`](@ref), which is a Julia wrapper type around an R object.

The `R""` string macro supports variable substitution of Julia objects via the `$` symbol, whenever it is not valid R syntax (i.e. when not directly following a symbol or completed expression such as `aa$bb`):

```@repl 1
x = randn(10)
R"t.test($x)"
```

It is also possible to pass Julia expressions which are evaluated before being passed to R: these should be included in parentheses

```@repl 1
R"optim(0, $(x -> x-cos(x)), method='BFGS')"
```

## `rcopy`

The [`rcopy`](@ref) function converts `RObject`s to Julia objects. It uses a variety of heuristics to pick the most appropriate Julia type:

```@repl 1
rcopy(R"c(1)")
rcopy(R"c(1,2)")
rcopy(R"list(1,'zz')")
rcopy(R"list(a=1,b='zz')")
```

It is possible to force a specific conversion by passing the output type as the first argument:

```@repl 1
rcopy(Array{Int},R"c(1,2)")
```
