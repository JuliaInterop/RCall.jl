using CategoricalArrays

# CategoricalArrays
v = CategoricalArray(repeat(["a", "b"], inner = 5))
@test isequal(rcopy(CategoricalArray,RObject(v)), v)
v = CategoricalArray(repeat(["a", "b"], inner = 5), ordered=true)
@test isequal(rcopy(CategoricalArray,RObject(v)), v)
@test CategoricalArrays.levels(rcopy(CategoricalArray,R"factor(c('a','a','c'))")) == ["a","c"]
@test CategoricalArrays.isordered(rcopy(CategoricalArray,R"ordered(c('a','a','c'))"))

if Pkg.installed("CategoricalArrays") < v"0.2.0"
    v = NullableCategoricalArray(repeat(["a", "b"], inner = 5), repeat([true, false], outer = 5))
    @test isequal(rcopy(NullableCategoricalArray,RObject(v)), v)
    v = NullableCategoricalArray(repeat(["a", "b"], inner = 5), repeat([true, false], outer = 5), ordered=true)
    @test isequal(rcopy(NullableCategoricalArray,RObject(v)), v)
    @test CategoricalArrays.levels(rcopy(NullableCategoricalArray,R"factor(c('a',NA,'c'))")) == ["a","c"]
    @test CategoricalArrays.isordered(rcopy(NullableCategoricalArray,R"ordered(c('a',NA,'c'))"))
else
    a = Array{Union{Null, String}}(repeat(["a", "b"], inner = 5))
    a[repeat([true, false], outer = 5)] = null
    v = CategoricalArray(a)
    @test isequal(rcopy(CategoricalArray,RObject(v)), v)
    v = CategoricalArray(a, ordered=true)
    @test isequal(rcopy(CategoricalArray,RObject(v)), v)
    @test CategoricalArrays.levels(rcopy(CategoricalArray,R"factor(c('a',NA,'c'))")) == ["a","c"]
    @test CategoricalArrays.isordered(rcopy(CategoricalArray,R"ordered(c('a',NA,'c'))"))
end
