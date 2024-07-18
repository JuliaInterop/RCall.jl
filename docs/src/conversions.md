# Supported Conversions

RCall supports conversions to and from most base Julia types and popular Statistics packages, e.g., `DataFrames`, `CategoricalArrays` and `AxisArrays`.

```@setup 1
using Pkg
Pkg.add("DataFrames")
Pkg.add("AxisArrays")

using RCall
using Dates
using DataFrames
using AxisArrays
```

## Base Julia Types

```@example 1
# Julia -> R
a = robject(1)
```

```@example 1
# R -> Julia
rcopy(a)
```

```@example 1
# Julia -> R
a = robject([1.0, 2.0])
```

```@example 1
# R -> Julia
rcopy(a)
```

## Dictionaries

```@example 1
# Julia -> R
d = Dict(:a => 1, :b => [4, 5, 3])
r = robject(d)
```

```@example 1
# R -> Julia
rcopy(r)
```

## Date

```@example 1
# Julia -> R
d = Date(2012, 12, 12)
r = robject(d)
```

```@example 1
# R -> Julia
rcopy(r)
```

## DateTime

```@example 1
# julia -> R
d = DateTime(2012, 12, 12, 12, 12, 12)
r = robject(d)
```

```@example 1
# R -> Julia
rcopy(r)
```

Note that R's `POSIXct` supports higher precision than DateTime:

```@example 1
r = reval("as.POSIXct('2020-10-09 12:09:46.1234')")
```

```@example 1
d = rcopy(r)
```

!!! note "Conversions to `DateTime` are given in UTC!"
    `POSIXct` stores times internally as UTC with a timezone attribute.
    The conversion to `DateTime` necessarily strips away timezone information, resulting in UTC values.

## DataFrames

```@example 1
d = DataFrame([[1.0, 4.5, 7.0]], [:x])
# Julia -> R
r = robject(d)
```

```@example 1
# R -> Julia
rcopy(r)
```

In default, the column names of R data frames are normalized such that `foo.bar`
would be replaced by `foo_bar`.

```@example 1
rcopy(R"data.frame(a.b = 1:3)")
```

To avoid the normalization, use `normalizenames` option.
```@example 1
rcopy(R"data.frame(a.b = 1:10)"; normalizenames = false)
```

## AxisArrays

```@example 1
# Julia -> R
aa = AxisArray([1,2,3], Axis{:id}(["a", "b", "c"]))
r = robject(aa)
```

```@example 1
# R -> Julia
rcopy(AxisArray, r)
```
