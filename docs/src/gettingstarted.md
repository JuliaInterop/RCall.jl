# Getting started

The RCall package is loaded via

```
julia> using RCall
```

This will initialize the R process in the background.

## `R""` string macro and `rcopy`

The simplest way to use RCall is via the `R""` string macro:

```
julia> x = R"rnorm(10)"
RCall.RObject{RCall.RealSxp}
 [1]  2.14715927 -1.54768482 -2.15976616 -0.60222806  0.53387481 -1.00477140
 [7]  1.59695873 -0.05140429  0.87452673  0.64201625
R"
```

This evaluates the expression inside the string, and returns the result as an `RObject`, which is a Julia wrapper around an R object. This can be converted to a native Julia object via `rcopy`:

```
julia> rcopy(x)
10-element Array{Float64,1}:
  2.14716  
 -1.54768  
 -2.15977  
 -0.602228 
  0.533875 
 -1.00477  
  1.59696  
 -0.0514043
  0.874527 
  0.642016 
```

R's `data.frame` objects are automatically converted to Julia `DataFrame`s:

```
julia> iris = rcopy(R"iris")
150x5 DataFrames.DataFrame
│ Row │ Sepal.Length │ Sepal.Width │ Petal.Length │ Petal.Width │ Species     │
┝━━━━━┿━━━━━━━━━━━━━━┿━━━━━━━━━━━━━┿━━━━━━━━━━━━━━┿━━━━━━━━━━━━━┿━━━━━━━━━━━━━┥
│ 1   │ 5.1          │ 3.5         │ 1.4          │ 0.2         │ "setosa"    │
│ 2   │ 4.9          │ 3.0         │ 1.4          │ 0.2         │ "setosa"    │
│ 3   │ 4.7          │ 3.2         │ 1.3          │ 0.2         │ "setosa"    │
...
```

The `R""` macro also supports substitution of Julia objects via the `$` symbol, whenever it is not valid R syntax (i.e. when not directly following a symbol such as `aa$bb`):

```
julia> R"lm(Sepal.Length ~ Sepal.Width + Species, data=$iris)"
RCall.RObject{RCall.VecSxp}

Call:
lm(formula = Sepal.Length ~ Sepal.Width + Species, data = `##RCall##1`)

Coefficients:
      (Intercept)        Sepal.Width  Speciesversicolor   Speciesvirginica  
           2.2514             0.8036             1.4587             1.9468  
```
