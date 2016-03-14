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
Most Linux distributions allow installation of R from their package manager, however these are often out of date, and may not work with RCall.jl. We recommend that you use the updated repositories from [CRAN](https://cran.r-project.org/bin/linux/).

#### Ubuntu
The following will update R on recent versions of Ubuntu:

    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
    sudo add-apt-repository -y "deb http://cran.rstudio.com/bin/linux/ubuntu $(lsb_release -s -c)/"
    sudo apt-get update -y
    sudo apt-get install -y r-base r-base-dev



## Updating R

If you have updated the R installation, you may need to rebuild the RCall cache via
```julia
Base.compilecache("RCall")
```
     
## Other methods

If you have installed R by some other method, then some further modifications may be necessary, for example, if you're building R from scratch, or the files have been copied but not installed in the usual manner (common on cluster installations).

Firstly, try setting the `R_HOME` environmental variable to the location of your R installation, which can be found by running `R.home()` from within R. This can be set in your `~/.juliarc.jl` file via the `ENV` global variable, e.g.
```julia
ENV["R_HOME"] = ...
```

### Windows PATH

The `PATH` environmental variable should contain the location of your R binary, and the `HOME` variable should contain the current user's home directory. These need to be set before Julia is started.

