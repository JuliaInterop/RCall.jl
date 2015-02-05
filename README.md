# RCall.jl

[![RCall](http://pkg.julialang.org/badges/RCall_release.svg)](http://pkg.julialang.org/?pkg=RCall&ver=release)

## Embedded R within Julia.

### Installation
To add the package, first ensure that both `R` and `Rscript` are on your search path, then start
`julia` and use
```julia
Pkg.add("RCall")
```

Adding or re-building the package should write a file whose name is the value of
```julia
Pkg.dir("RCall","deps","deps.jl")
```
This file sets several environment values and defines a string `libR`.  You may want to check these values.

### Attaching the package
Attaching the package in a Julia session with
```julia
using RCall
```
should start an embedded R.

Please file an issue at the [github repository](https://github.com/JuliaStats/RCall.jl) for the package if this fails.

## Usage

### Accessing R data sets

The simplest usage of the `RCall` package is to access datasets included with `R` packages.

For example, the `datasets` package, which is one of the standard packages attached to an `R` session, contains a dataset called `attenu`.
```julia
attenu = dataset(:attenu)
```
imports the data set into a `julia` session.

### The `R` module

Several convenience functions for R are contained in the module called `R` which is exported by the `RCall` package.  These include, `R.ls`, `R.str`, and `R.library`.  To list the objects in the datasets package use
```julia
R.ls("datasets")
```

To attach the `ggplot2` package to the embedded `R` session and access the `diamonds` dataset, use
```julia
R.library(:gglplot2)
diamonds = dataset(:diamonds)
```

### Assigning and accessing values from the R global environment

R objects can be assigned to an environment in `R` (typically the `globalEnv`) and accessed from that environment using Julia indexing operations.  It often helps to assign a shorter name than `globalEnv`, as in
```julia
g = globalEnv
g[:x] = 1
```

### Conversion between Julia and R representations

It helps to know a bit about the internal structure of `R`.
Most `R` objects are instances of a `C` struct called an `SEXPREC` (symbolic expression).  A pointer to such an object is called an `SEXP`.  Most of the `C` functions in the `R` interface take one or more `SEXP` values as arguments and return an `SEXP`.

There are several types of `SEXPREC`.  The type is determined by a numeric code in the lowest-order 5 bits of an integer at the beginning of the structure.  These are displayed in Julia as, e.g.
````julia
julia> form = reval(:Formaldehyde)
RCall.SEXP{19}(Ptr{Void} @0x000000000f89c500)
````
It happens that 19 is the code for an R `list` type (somewhat confusingly called a `VECSXP`).

Conversions from a Julia type to an R SEXPREC is performed by the `sexp` function.
Obviously not all Julia objects will have a counterpart in R.

Conversion an R SEXP to a Julia type is usually performed by methods for `vec` or for `dataset`.  The difference between the two is that `vec` produces a Julia vector type whereas `dataset` produces a `DataArray` or `DataFrame` type that allows for missing values (`NA`'s).

## Direct calls to R's `parse` and `eval`

The functions `rparse` and `reval` provide direct access to the parse/eval mechanism in `R`.

There are several utilities (`lang1` to `lang6`) for creating R function calls.
When in doubt, the simplest course is to use `reval(rparse(str))` where `str` is a string.
