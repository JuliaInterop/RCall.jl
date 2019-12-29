using CategoricalArrays

# CategoricalArrays
v = CategoricalArray(repeat(["b", "a"], inner = 5))
@test isequal(rcopy(CategoricalArray,RObject(v)), v)
v = CategoricalArray(repeat(["b", "a"], inner = 5), ordered=true)
@test isequal(rcopy(CategoricalArray,RObject(v)), v)
@test CategoricalArrays.levels(rcopy(CategoricalArray,R"factor(c('c','a','a'))")) == ["a","c"]
@test CategoricalArrays.isordered(rcopy(CategoricalArray,R"ordered(c('c','a','a'))"))

a = Array{Union{String, Missing}}(repeat(["b", "a"], inner = 5))
a[repeat([true, false], outer = 5)] .= missing
v = CategoricalArray(a)
@test isequal(rcopy(CategoricalArray,RObject(v)), v)
v = CategoricalArray(a, ordered=true)
@test isequal(rcopy(CategoricalArray,RObject(v)), v)
@test CategoricalArrays.levels(rcopy(CategoricalArray,R"factor(c('c',NA,'a'))")) == ["a","c"]
@test CategoricalArrays.isordered(rcopy(CategoricalArray,R"ordered(c('c',NA,'a'))"))
