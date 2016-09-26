using NullableArrays,CategoricalArrays,DataFrames

v110 = rcopy(NullableArray,reval("c(1L, NA)"))
@test isa(v110,NullableVector)
@test eltype(v110) == Nullable{Int32}
@test rcopy(NullableArray, RObject(v110[2]))[1].isnull

attenu = rcopy(DataFrame,:attenu)
@test isa(attenu,DataFrame)
@test size(attenu) == (182,5)

dist = attenu[:dist]
@test isa(dist,NullableArray{Float64})

@test rcopy(NullableArray,"c(NA,TRUE)").isnull == NullableArray([Nullable(),true]).isnull
@test rcopy(NullableArray,"c(NA,1)").isnull == NullableArray([Nullable(),1.0]).isnull
@test rcopy(NullableArray,"c(NA,1+0i)").isnull == NullableArray([Nullable(),1.0+0.0*im]).isnull
@test rcopy(NullableArray,"c(NA,1L)").isnull == NullableArray([Nullable(),one(Int32)]).isnull
@test rcopy(NullableArray,"c(NA,'NA')").isnull == NullableArray([Nullable(),"NA"]).isnull
@test_throws ErrorException rcopy(NullableArray,"as.factor(c('a','a','c'))")
@test rcopy(NullableCategoricalArray,"as.factor(c('a','a','c'))").pool.levels == ["a","c"]

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
pda = NullableCategoricalArray(repeat(["a", "b"], inner = [5]))
@test rcopy(NullableCategoricalArray,RObject(pda)).refs == repeat([1,2], inner = [5])

@test rcopy(rcall(:dim,RObject(attenu))) == [182,5]
