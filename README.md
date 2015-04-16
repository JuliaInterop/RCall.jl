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

## Documentation

- [RCall](https://cdn.rawgit.com/JuliaStats/RCall.jl/master/doc/RCall.html)
- [Mapping API](https://cdn.rawgit.com/JuliaStats/RCall.jl/master/doc/MappingAPI.html)
- [Graphics](https://cdn.rawgit.com/JuliaStats/RCall.jl/master/doc/graphics.html)