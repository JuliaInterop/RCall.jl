using NullableArrays,CategoricalArrays,DataFrames

v110 = rcopy(NullableArray,reval("c(1L, NA)"))
@test isa(v110,NullableVector)
@test eltype(v110) == Nullable{Int32}
@test rcopy(NullableArray, RObject(v110[2]))[1].isnull

attenu = rcopy(DataFrame,:attenu)
@test isa(attenu,DataFrame)
@test size(attenu) == (182,5)

dist = attenu[:dist]
@test isa(dist,Vector{Float64})
station = attenu[:station]
@test isa(station,NullableCategoricalArray)

@test rcopy(NullableArray,"c(NA,TRUE)").isnull == NullableArray([true,true], [true,false]).isnull
@test rcopy(NullableArray,"c(NA,1)").isnull == NullableArray([true,1.], [true,false]).isnull
@test rcopy(NullableArray,"c(NA,1+0i)").isnull == NullableArray([true,1.+0*im], [true,false]).isnull
@test rcopy(NullableArray,"c(NA,1L)").isnull == NullableArray([true,one(Int32)], [true,false]).isnull
@test rcopy(NullableArray,"c(NA,'NA')").isnull == NullableArray(["", "NA"], [true,false]).isnull
@test_throws ErrorException rcopy(NullableArray,"as.factor(c('a','a','c'))")
@test rcopy(CategoricalArray,"factor(c('a','a','c'))").pool.levels == ["a","c"]
@test rcopy(NullableCategoricalArray,"factor(c('a',NA,'c'))").pool.levels == ["a","c"]
@test rcopy(CategoricalArray,"ordered(c('a','a','c'))").pool.ordered
@test rcopy(NullableCategoricalArray,"ordered(c('a',NA,'c'))").pool.ordered

v = NullableArray([true,true], [true,false])
@test rcopy(NullableArray,RObject(v)).isnull == v.isnull
v = NullableArray([1,2], [true,false])
@test rcopy(NullableArray,RObject(v)).isnull == v.isnull
v = NullableArray([1.,2.], [true,false])
@test rcopy(NullableArray,RObject(v)).isnull == v.isnull
v = NullableArray([0,1.+0*im], [true,false])
@test rcopy(NullableArray,RObject(v)).isnull == v.isnull
v = NullableArray(["","abc"], [true,false])
@test rcopy(NullableArray,RObject(v)).isnull == v.isnull
ca = CategoricalArray(repeat(["a", "b"], inner = 5))
@test rcopy(CategoricalArray,RObject(ca)).refs == ca.refs
nca = NullableCategoricalArray(repeat(["a", "b"], inner = 5), repeat([true, false], outer = 5))
@test rcopy(NullableCategoricalArray,RObject(nca)).refs == nca.refs
ca = CategoricalArray(repeat(["a", "b"], inner = 5), ordered=true)
@test rcopy(CategoricalArray,RObject(ca)).pool.ordered
nca = NullableCategoricalArray(repeat(["a", "b"], inner = 5), repeat([true, false], outer = 5), ordered=true)
@test rcopy(NullableCategoricalArray,RObject(ca)).pool.ordered

@test rcopy(rcall(:dim,RObject(attenu))) == [182,5]
