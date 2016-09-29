using NullableArrays,CategoricalArrays,DataFrames

@test isequal(rcopy(Nullable, RObject(1)), Nullable(1))
@test isequal(rcopy(Nullable, RObject("abc")), Nullable("abc"))
@test rcopy(RObject(Nullable(1))) == 1
@test isnull(rcopy(Nullable, RObject(Nullable(1, true))))

v110 = rcopy(NullableArray,reval("c(1L, NA)"))
@test isa(v110,NullableVector)
@test eltype(v110) == Nullable{Int32}
@test isnull(rcopy(NullableArray, RObject(v110[2]))[1])

attenu = rcopy(DataFrame,:attenu)
@test isa(attenu,DataFrame)
@test size(attenu) == (182,5)

dist = attenu[:dist]
@test isa(dist,Vector{Float64})
station = attenu[:station]
@test isa(station,NullableCategoricalArray)

@test isequal(rcopy(NullableArray,"c(NA,TRUE)"), NullableArray([true,true], [true,false]))
@test isequal(rcopy(NullableArray,"c(NA,1)"), NullableArray([true,1.], [true,false]))
@test isequal(rcopy(NullableArray,"c(NA,1+0i)"), NullableArray([true,1.+0*im], [true,false]))
@test isequal(rcopy(NullableArray,"c(NA,1L)"), NullableArray([true,one(Int32)], [true,false]))
@test isequal(rcopy(NullableArray,"c(NA,'NA')"), NullableArray(["", "NA"], [true,false]))
@test_throws ErrorException rcopy(NullableArray,"as.factor(c('a','a','c'))")
@test CategoricalArrays.levels(rcopy(CategoricalArray,"factor(c('a','a','c'))")) == ["a","c"]
@test CategoricalArrays.levels(rcopy(NullableCategoricalArray,"factor(c('a',NA,'c'))")) == ["a","c"]
@test CategoricalArrays.ordered(rcopy(CategoricalArray,"ordered(c('a','a','c'))"))
@test CategoricalArrays.ordered(rcopy(NullableCategoricalArray,"ordered(c('a',NA,'c'))"))

v = NullableArray([true,true], [true,false])
@test isequal(rcopy(NullableArray,RObject(v)), v)
v = NullableArray([1,2], [true,false])
@test isequal(rcopy(NullableArray,RObject(v)), v)
v = NullableArray([1.,2.], [true,false])
@test isequal(rcopy(NullableArray,RObject(v)), v)
v = NullableArray([0,1.+0*im], [true,false])
@test isequal(rcopy(NullableArray,RObject(v)), v)
v = NullableArray(["","abc"], [true,false])
@test isequal(rcopy(NullableArray,RObject(v)), v)
v = CategoricalArray(repeat(["a", "b"], inner = 5))
@test isequal(rcopy(CategoricalArray,RObject(v)), v)
v = NullableCategoricalArray(repeat(["a", "b"], inner = 5), repeat([true, false], outer = 5))
@test isequal(rcopy(NullableCategoricalArray,RObject(v)), v)
v = CategoricalArray(repeat(["a", "b"], inner = 5), ordered=true)
@test isequal(rcopy(CategoricalArray,RObject(v)), v)
v = NullableCategoricalArray(repeat(["a", "b"], inner = 5), repeat([true, false], outer = 5), ordered=true)
@test isequal(rcopy(NullableCategoricalArray,RObject(v)), v)

@test rcopy(rcall(:dim,RObject(attenu))) == [182,5]
