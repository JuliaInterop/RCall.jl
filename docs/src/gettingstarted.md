# Getting started

The RCall package is loaded via

```@repl 1
using RCall
```

This will initialize the R process in the background.


## Several Ways to use RCall

RCall provides multiple ways to allow R interacting with Julia. 

- R REPL mode
- [`@rput`](@ref) and [`@rget`](@ref) macros
- `R""` string macro
- A low level API: [`reval`](@ref), [`rcall`](@ref) and [`rcopy`](@ref) etc.

## R REPL mode
The R REPL mode allows real time switching between the Julia prompt and R promot. Press `$` to activate the R REPL mode and the R prompt will be shown. (Press `backspace` to leave R REPL mode in case you did not know.)

```r
julia> foo = 1
1

R> x <- $foo

R> x
[1] 1
```

The R REPL mode supports variable substitution of Julia objects via the `$` symbol. It is also possible to pass Julia expressions in the REPL mode.

```r
R> x = $(rand(10))

R> sum(x)
[1] 5.097083
```

## @rput and @rget macros

These macros transfer variables between R and Julia environments. The copied variable will have the same name as the original.

```r
julia> z = 1
1

julia> @rput z
1

R> z
[1] 1

R> r = 2

julia> @rget r
2.0

julia> r
2.0
```

It is also possible to put and get multiple variables in one line.

```r
julia> foo = 2
2

julia> bar = 4
4

julia> @rput foo bar
4

R> foo + bar
[1] 6
```

## @R_str string macro

Another way to use RCall is the [`R""`](@ref) string macro, it is especially useful in script files.

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

A large chunk of code could be quoted between triple string quotations

```@repl 1
y = 1
R"""
f <- function(x, y) x + y
ret <- f(1, $y)
"""
```


## RCall API

The [`reval`](@ref) function evaluates any given input string as R code in the R environment. The returned result is an `RObject` object.

```@repl 1
jmtcars = reval("mtcars");
names(jmtcars)
jmtcars[:mpg]
typeof(jmtcars)
```

The [`rcall`](@ref) function is used to construct function calls.

```@repl 1
rcall(:dim, jmtcars)
```

The arguments will be implicitly converted to `RObject` upon evaluation.

```@repl 1
rcall(:sum, Float64[1.0, 4.0, 6.0])
```

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
