# Installing RCall.jl

RCall.jl can simply be installed with
```julia
Pkg.add("RCall")
```

RCall.jl will automatically install R for you using [Conda](https://github.com/JuliaPy/Conda.jl)
if it doesn't detect that you have R 3.4.0 or later installed already.

## Customizing the R installation

Before installing its own copy of R, the RCall build script (run by `Pkg.add`)
will check for an existing R installation by looking in the following locations,
in order.

* The `R_HOME` environment variable, if set, should be the location of the
  [R home directory](https://stat.ethz.ch/R-manual/R-devel/library/base/html/Rhome.html).
* Otherwise, it runs the `R HOME` command, assuming `R` is located in your [`PATH`](https://en.wikipedia.org/wiki/PATH_(variable)).
* Otherwise, on Windows, it looks in the [Windows registry](https://cran.r-project.org/bin/windows/base/rw-FAQ.html#Does-R-use-the-Registry_003f).
* Otherwise, it installs the [`r-base` package](https://anaconda.org/r/r-base).

To change which R installation is used for RCall, set the `R_HOME` environment variable
and run `Pkg.build("RCall")`.   Once this is configured, RCall remembers the location
of R in future updates, so you don't need to set `R_HOME` permanently.

You can set `R_HOME` to the empty string `""` to force `Pkg.build` to re-run the
`R HOME` command, e.g. if you change your PATH:
```julia
ENV["R_HOME"]=""
ENV["PATH"]="....directory of R executable..."
Pkg.build("RCall")
```

When `R HOME` doesn't return a valid R library or `R_HOME` is set to `"*"`, RCall will use its own Conda installation of R.


Should you experience problems with any of these methods, please [open an issue](https://github.com/JuliaStats/RCall.jl/issues/new).

## Standard installations

If you want to install R yourself, rather than relying on the automatic Conda installation, you can use one of the following options:

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

### Other methods

If you have installed R by some other method (e.g. building from scratch, or files copied but not installed in the usual manner), which often happens on cluster installations, then you may need to set `R_HOME` or your `PATH` as described above before running `Pkg.build("RCall")` in order for the build script to find your R installation. RCall requries R to be installed with its shared library. It could be done with the flag `--enable-R-shlib`, consult your server administrator if see if it was the caase.

For some environments, you might also need to specify `LD_LIBRARY_PATH`
```sh
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:`R RHOME`/lib"
```


## Updating R

If you have updated your R installation, you may need to re-run `Pkg.build("RCall")`
as described above, possibly changing the `R_HOME` environment variable first.
