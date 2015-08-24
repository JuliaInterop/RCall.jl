# RCall.jl

Linux & OSX: [![Travis Build Status](https://travis-ci.org/JuliaStats/RCall.jl.svg?branch=master)](https://travis-ci.org/JuliaStats/RCall.jl)

Windows: [![Appveyor Build Status](https://ci.appveyor.com/api/projects/status/y3kxma63apcig150/branch/master?svg=true)](https://ci.appveyor.com/project/simonbyrne/rcall-jl)

Pkg: [![PkgEval status](http://pkg.julialang.org/badges/RCall_release.svg)](http://pkg.julialang.org/?pkg=RCall&ver=release) [![pkg.julialang.org status](http://pkg.julialang.org/badges/RCall_0.4.svg)](http://pkg.julialang.org/?pkg=RCall&ver=nightly)

Coverage: [![Coveralls Status](https://coveralls.io/repos/JuliaStats/RCall.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaStats/RCall.jl?branch=master)

## Embedded R within Julia.

### Requirements and Installation

This package requires that a recent version of R be installed. Then running
```julia
Pkg.add("RCall")
```
from within Julia should be sufficient. For further details, see the [Installing RCall.jl](doc/Installation.md).

### Attaching the package
Attaching the package in a Julia session with
```julia
using RCall
```
should start an embedded R.

## Documentation

- [Introduction](doc/RCall.md)
- [RCall](https://rawgit.com/JuliaStats/RCall.jl/master/doc/RCall.html)
- [Mapping API](https://rawgit.com/JuliaStats/RCall.jl/master/doc/MappingAPI.html)
- [Graphics](https://rawgit.com/JuliaStats/RCall.jl/master/doc/graphics.html)
