# RCall.jl

## Embedded R within Julia.

Current status:
- The package is not yet registered as it still in a state of flux.
- You must have `R` and `Rscript` on your search path to add or build the package.
- To add the package use
```julia
Pkg.clone("https://github.com/JuliaStats/RCall.jl")
```
- To (re)build the package after you have cloned it, use
```julia
Pkg.build("RCall")
```
- Building the package should write a file whose name is the value of
```julia
Pkg.dir("RCall","deps","deps.jl")
```
This file sets several environment values and defines a string `libR`.  You may want to check these values.
- Attaching the package with
```julia
using RCall
```
should start an embedded R.
- This probably won't work if the default version of R on your system is Revolution R Open (RRO), which uses its own BLAS/LAPACK setup.  (If someone discovers how to make this work please file an issue.)

## Usage

It helps to know a bit about the internal structure of `R`.
Most `R` objects are instances of a `C` struct called an `SEXPREC` (symbolic expression).  A pointer to such an object is called an `SEXP`.  Most of the `C` functions in the `R` interface take one or more `SEXP` values as arguments and return an `SEXP`.

There are several types of `SEXPREC`.  The type is determined by a numeric code in the lowest-order 5 bits of an integer at the beginning of the structure.  These are displayed in Julia as, e.g.
````julia
julia> using RCall

julia> form = Reval(:Formaldehyde)
RCall.SEXP{19}(Ptr{Void} @0x000000000f89c500)

````





It happens that 19 is the code for an `R` `list` object.  Initially I would recommend applying `R.str` to an `SEXP` value in the package to get a brief printed summary (from R) of the object.
````julia
julia> R.str(form);
'data.frame':   6 obs. of  2 variables:
 $ carb  : num  0.1 0.3 0.5 0.6 0.7 0.9
 $ optden: num  0.086 0.269 0.446 0.538 0.626 0.782
````




R's `str` function is extremely versatile.
````julia
julia> R.str(Reval(:ls));
function (name, pos = -1L, envir = as.environment(pos), all.names = FALSE, pattern)
````





Remember, this output is being generated in `R`.  The semicolon at the end of the Julia expression does not suppress the output from R.

The `RCall` package uses the `Rf_tryEval` function in the `R` API to evaluate expressions, so that errors in R are caught.  As seen above, evaluating a symbol returns the value of that symbol in R's global environment.  Simple function calls can be created using functions named `lang<k>`, where `k` is the number of arguments to the R function plus 1.  The first argument to `lang<k>` is a R symbol giving the name of the R function.

An R symbol is accessed (installing the symbol in the symbol table, if necessary) with the Julia function `install`.
````julia
julia> search = Reval(lang1(install(:search)))
RCall.SEXP{16}(Ptr{Void} @0x000000000f90caa8)

````





The value of an R object can be imported into Julia using the (currently unexported) `rawvector`` function.  This function is not exported because I don't like the name but haven't thought of a better one.  Also, it will be important to settle on who protects the contents and who unprotects them.
````julia
julia> RCall.rawvector(search)
13-element Array{ASCIIString,1}:
 ".GlobalEnv"
 "package:mlmRev"
 "package:lme4"
 "package:Rcpp"
 "package:Matrix"
 "package:stats"
 "package:graphics"
 "package:grDevices"
 "package:utils"
 "package:datasets" 
 "package:methods"
 "Autoloads"
 "package:base"
````





There is also a function `Rprint` that uses R's printing mechanism.
````julia
julia> Rprint(search)
 [1] ".GlobalEnv"        "package:mlmRev"    "package:lme4"
 [4] "package:Rcpp"      "package:Matrix"    "package:stats"
 [7] "package:graphics"  "package:grDevices" "package:utils"
[10] "package:datasets"  "package:methods"   "Autoloads"
[13] "package:base"
````





To parse a string as an R expression, use `Rparse`.
````julia
julia> RCall.rawvector(Reval(Rparse("2+2")))
1-element Array{Float64,1}:
 4.0

````




