using CategoricalArrays

# CategoricalArrays
for ord in (true, false)
    v = CategoricalArray(repeat(["b", "a"], inner = 5), ordered=ord)
    v2 = rcopy(CategoricalArray, RObject(v))
    @test isequal(v2, v)
    @test v2 isa CategoricalVector{String}
    @test levels(v2) == levels(v)
    @test isordered(v2) === ord
end
@test levels(rcopy(CategoricalArray, R"factor(c('c','a','a'))")) == ["a","c"]
@test !isordered(rcopy(CategoricalArray, R"factor(c('c','a','a'))"))
@test isordered(rcopy(CategoricalArray, R"ordered(c('c','a','a'))"))

a = Array{Union{String, Missing}}(repeat(["b", "a"], inner = 5))
a[repeat([true, false], outer = 5)] .= missing
for ord in (true, false)
    v = CategoricalArray(a, ordered=ord)
    v2 = rcopy(CategoricalArray, RObject(v))
    @test isequal(v2, v)
    @test v2 isa CategoricalVector{Union{String,Missing}}
    @test levels(v2) == levels(v)
    @test isordered(v2) === ord
end
@test levels(rcopy(CategoricalArray, R"factor(c('c',NA,'a'))")) == ["a","c"]
@test !isordered(rcopy(CategoricalArray, R"factor(c('c',NA,'a'))"))
@test isordered(rcopy(CategoricalArray, R"ordered(c('c',NA,'a'))"))
