# RCall.jl

[![Build Status](https://travis-ci.org/JuliaStats/RCall.jl.svg?branch=master)](https://travis-ci.org/JuliaStats/RCall.jl)
[![RCall](http://pkg.julialang.org/badges/RCall_release.svg)](http://pkg.julialang.org/?pkg=RCall&ver=release)

## Embedded R within Julia.

### Installation
To add the package, first ensure that both `R` and `Rscript` are on your search path, then start
`julia` and enter
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

For example, R's `datasets` package, which is one of the standard packages attached to an `R` session, contains a dataset called `attenu`.
```julia
attenu = DataFrame(:attenu)
```
imports the data set into a `julia` session.

### Assigning and accessing values from the R global environment

R objects can be assigned to an environment in `R` (typically the `globalEnv`) and accessed from that environment using Julia indexing operations.  It often helps to assign a shorter name than `globalEnv`, as in
```julia
g = globalEnv
g[:x] = 1
```
