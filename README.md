# RCall.jl

Linux & OSX: [![Travis Build Status](https://travis-ci.org/JuliaStats/RCall.jl.svg?branch=master)](https://travis-ci.org/JuliaStats/RCall.jl)

Windows: [![Appveyor Build Status](https://ci.appveyor.com/api/projects/status/y3kxma63apcig150/branch/master?svg=true)](https://ci.appveyor.com/project/simonbyrne/rcall-jl)

Pkg: [![PkgEval status](http://pkg.julialang.org/badges/RCall_release.svg)](http://pkg.julialang.org/?pkg=RCall&ver=release) [![pkg.julialang.org status](http://pkg.julialang.org/badges/RCall_0.4.svg)](http://pkg.julialang.org/?pkg=RCall&ver=nightly)

Coverage: [![Coveralls Status](https://coveralls.io/repos/JuliaStats/RCall.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaStats/RCall.jl?branch=master)

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

- [Introduction](doc/RCall.md)
- [RCall](https://rawgit.com/JuliaStats/RCall.jl/master/doc/RCall.html)
- [Mapping API](https://rawgit.com/JuliaStats/RCall.jl/master/doc/MappingAPI.html)
- [Graphics](https://rawgit.com/JuliaStats/RCall.jl/master/doc/graphics.html)
