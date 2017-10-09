# Supported Conversions

RCall supports conversions to and from most base Julia types and popular Statistics packages, e.g., `DataFrames`, `DataArrays`, `NullableArrays`, `CategoricalArrays` `NamedArrays` and `AxisArrays`.

```@setup 1
using RCall
using DataFrames
using NamedArrays
using AxisArrays
```

## Base Julia Types

```@example 1
# Julia -> R
a = RObject(1)
```

```@example 1
# R -> Julia
rcopy(a)
```

```@example 1
# Julia -> R
a = RObject([1.0, 2.0])
```

```@example 1
# R -> Julia
rcopy(a)
```

## Dictionaries

```@example 1
# Julia -> R
d = Dict(:a => 1, :b => [4, 5, 3])
r = RObject(d)
```

```@example 1
# R -> Julia
rcopy(r)
```

## Date

```@example 1
# Julia -> R
d = Date(2012, 12, 12)
r = RObject(d)
```

```@example 1
# R -> Julia
rcopy(r)
```

## DateTime

```@example 1
# julia -> R
d = DateTime(2012, 12, 12, 12, 12, 12)
r = RObject(d)
```

```@example 1
# R -> Julia
rcopy(r)
```

## DataFrames and DataArrays

```@example 1
d = DataFrame([[1.0, 4.5, 7.0]], [:x])
# Julia -> R
r = RObject(d)
```

```@example 1
# R -> Julia
rcopy(r)
```

In default, the column names of R data frames are sanitized such that `foo.bar`
would be replaced by `foo_bar`.

```@example 1
rcopy(R"data.frame(a.b = 1:3)")
```

To avoid the sanitization, use `sanitize` option.
```@example 1
rcopy(R"data.frame(a.b = 1:10)"; sanitize = false)
```

## NamedArrays

```@example 1
# Julia -> R
aa = NamedArray([1,2,3], [["a", "b", "c"]], [:id])
r = RObject(aa)
```

```@example 1
# R -> Julia
rcopy(NamedArray, r)
```


## AxisArrays

```@example 1
# Julia -> R
aa = AxisArray([1,2,3], Axis{:id}(["a", "b", "c"]))
r = RObject(aa)
```

```@example 1
# R -> Julia
rcopy(AxisArray, r)
```
