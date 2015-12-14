# Installing RCall.jl

RCall.jl requires that a recent version of R, at least 3.2.0, be installed. 

## Standard installations

If R has been installed using one of the standard approaches below, then RCall.jl can simply be installed with
```julia
Pkg.add("RCall")
```
Should you experience problems with any of these methods, please [open an issue](https://github.com/JuliaStats/RCall.jl/issues/new).


### Windows
The current [Windows binary from CRAN](https://cran.r-project.org/bin/windows/base/).

### OS X
The [CRAN .pkg](https://cran.r-project.org/bin/macosx/) or the [homebrew/science](https://github.com/Homebrew/homebrew-science) tap.

### Linux
Most linux distributions allow installation of R from their package manager, however these are often out of date, and may not work with RCall.jl. We recommend that you use the updated repositories from [CRAN](https://cran.r-project.org/bin/linux/).


## Updating R

If you have updated the R installation, you may need to rebuild RCall via
```julia
Pkg.build("RCall")
```
This should be done from within a new Julia session (i.e. before RCall has been loaded).


## Other methods

If you have installed R by some other method, then some further modifications may be necessary, for example, if you're building R from scratch, or the files have been copied but not installed in the usual manner (common on cluster installations).

### Linux and OS X
The following environmental variables should be set:
 * `R_HOME`
 * `R_DOC_DIR`
 * `R_INCLUDE_DIR`
 * `R_SHARE_DIR`
 * `LD_LIBRARY_PATH`

These can be set in your `~/.juliarc.jl` file via the `ENV` global variable, e.g.
```julia
ENV["R_HOME"] = ...
```

Then from withing Julia, try running
```julia
Pkg.build("RCall")
```

### Windows
The `PATH` environmental variable should contain your R binary, and the `HOME` variable should contain the current user's home directory. These need to be set before Julia is started.

