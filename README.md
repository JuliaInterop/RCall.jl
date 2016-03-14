# RCall.jl

#### Most recent release
[![RCall](http://pkg.julialang.org/badges/RCall_0.4.svg)](http://pkg.julialang.org/?pkg=RCall&ver=0.4)
[![RCall](http://pkg.julialang.org/badges/RCall_0.5.svg)](http://pkg.julialang.org/?pkg=RCall&ver=0.5)

#### Development version
* Linux & OSX: [![Travis Build Status](https://travis-ci.org/JuliaStats/RCall.jl.svg?branch=master)](https://travis-ci.org/JuliaStats/RCall.jl)
* Windows: [![Appveyor Build Status](https://ci.appveyor.com/api/projects/status/y3kxma63apcig150/branch/master?svg=true)](https://ci.appveyor.com/project/simonbyrne/rcall-jl)
* Coverage: [![Coveralls Status](https://coveralls.io/repos/JuliaStats/RCall.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaStats/RCall.jl?branch=master)

#### Lastest Documentataion

[Latest Documentation](http://juliastats.github.io/RCall.jl/latest).
 
## Embedded R within Julia.

### Requirements and Installation

This package requires that a recent version of R (3.2.0 or greater) be installed. Then running
```julia
Pkg.add("RCall")
```
from within Julia should be sufficient. For further details, see [Installing RCall.jl](http://juliastats.github.io/RCall.jl/latest/installation/).

### Attaching the package
Attaching the package in a Julia session with
```julia
using RCall
```
should start an embedded R.
