# Installing RCall.jl

## Supported methods

RCall.jl requires that a recent version of R, at least 3.2.0, be installed. Currently supported are:
 * Windows: The Windows binary from [CRAN](https://cran.r-project.org/bin/windows/base/).
 * Mac OS X: The [CRAN .pkg](https://cran.r-project.org/bin/macosx/) or the [homebrew/science](https://github.com/Homebrew/homebrew-science) tap.
 * Linux: most distributions allow installation of R from their package manager, however these are often older versions which may not work with RCall.jl. We recommend that you use the updated repositories from [CRAN](https://cran.r-project.org/bin/linux/).

If R has been installed by any of these methods, it should be possible to install RCall.jl from within Julia using
```julia
Pkg.add("RCall")
```
Should you experience problems with any of these methods, please [open an issue](https://github.com/JuliaStats/RCall.jl/issues/new).

### Updating

If you have updated the R installation, you may need to rebuild RCall via
```julia
Pkg.build("RCall")
```
This should be done from within a new Julia session (i.e. before RCall has been loaded).


## Other methods

If you're using some sort of other installation, then some further modifications may be necessary, for example, if you're building R from scratch, or the files have been copied but not installed in the usual manner (common on cluster installations).

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

