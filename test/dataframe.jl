using NullableArrays,CategoricalArrays,DataFrames

@test isequal(rcopy(Nullable, RObject(1)), Nullable(1))
@test isequal(rcopy(Nullable, RObject("abc")), Nullable("abc"))
@test rcopy(RObject(Nullable(1))) == 1
@test isnull(rcopy(Nullable, RObject(Nullable())))

v110 = rcopy(NullableArray,reval("c(1L, NA)"))
@test isa(v110,NullableVector)
@test eltype(v110) == Nullable{Int32}
@test isnull(rcopy(NullableArray, RObject(v110[2]))[1])

attenu = rcopy(DataFrame,:attenu)
@test isa(attenu,DataFrame)
@test size(attenu) == (182,5)
@test rcopy(rcall(:dim,RObject(attenu))) == [182,5]
@test nrow(by(df -> R"lm(data=$df, dist  ~ accel)", attenu, :event)) == 23

dist = attenu[:dist]
@test isa(dist,Vector{Float64})
station = attenu[:station]
@test isa(station,NullableCategoricalArray)

# NullableArrays
# bool
v = NullableArray([true,true], [true,false])
@test isequal(rcopy(NullableArray,RObject(v)), v)
v = NullableArray([true,true], [false,true])
@test isequal(rcopy(NullableArray,RObject(v)), v)
@test isequal(rcopy(NullableArray,"c(NA,TRUE)"), NullableArray([true,true], [true,false]))
@test isequal(rcopy(NullableArray,"c(TRUE, NA)"), NullableArray([true,true], [false,true]))
# int64
v = NullableArray([1,2], [true,false])
@test isequal(rcopy(NullableArray,RObject(v)), v)
v = NullableArray([1,2], [false,true])
@test isequal(rcopy(NullableArray,RObject(v)), v)
@test isequal(rcopy(NullableArray,"c(NA,1L)"), NullableArray([0,1], [true,false]))
@test isequal(rcopy(NullableArray,"c(1L,NA)"), NullableArray([1,0], [false,true]))
# int32
v = NullableArray(Int32[1,2], [true,false])
@test isequal(rcopy(NullableArray,RObject(v)), v)
v = NullableArray(Int32[1,2], [false,true])
@test isequal(rcopy(NullableArray,RObject(v)), v)
@test isequal(rcopy(NullableArray,"c(NA,1L)"), NullableArray(Int32[0,1], [true,false]))
@test isequal(rcopy(NullableArray,"c(1L,NA)"), NullableArray(Int32[1,0], [false,true]))
# real
v = NullableArray([1.,2.], [true,false])
@test isequal(rcopy(NullableArray,RObject(v)), v)
v = NullableArray([1.,2.], [false,true])
@test isequal(rcopy(NullableArray,RObject(v)), v)
@test isequal(rcopy(NullableArray,"c(NA,1)"), NullableArray([0,1.], [true,false]))
@test isequal(rcopy(NullableArray,"c(1,NA)"), NullableArray([1.,0], [false,true]))
# complex
v = NullableArray([0,1.+0*im], [true,false])
@test isequal(rcopy(NullableArray,RObject(v)), v)
v = NullableArray([0,1.+0*im], [false,true])
@test isequal(rcopy(NullableArray,RObject(v)), v)
@test isequal(rcopy(NullableArray,"c(NA,1+0i)"), NullableArray([0,1.+0*im], [true,false]))
@test isequal(rcopy(NullableArray,"c(1+0i,NA)"), NullableArray([1.+0*im,0], [false,true]))
# string
v = NullableArray(["","abc"], [true,false])
@test isequal(rcopy(NullableArray,RObject(v)), v)
v = NullableArray(["","abc"], [false,true])
@test isequal(rcopy(NullableArray,RObject(v)), v)
@test isequal(rcopy(NullableArray,"c(NA,'NA')"), NullableArray(["","NA"], [true,false]))
@test isequal(rcopy(NullableArray,"c('NA',NA)"), NullableArray(["NA",""], [false,true]))

# CategoricalArrays
v = CategoricalArray(repeat(["a", "b"], inner = 5))
@test isequal(rcopy(CategoricalArray,RObject(v)), v)
v = NullableCategoricalArray(repeat(["a", "b"], inner = 5), repeat([true, false], outer = 5))
@test isequal(rcopy(NullableCategoricalArray,RObject(v)), v)
v = CategoricalArray(repeat(["a", "b"], inner = 5), ordered=true)
@test isequal(rcopy(CategoricalArray,RObject(v)), v)
v = NullableCategoricalArray(repeat(["a", "b"], inner = 5), repeat([true, false], outer = 5), ordered=true)
@test isequal(rcopy(NullableCategoricalArray,RObject(v)), v)
@test_throws ErrorException rcopy(NullableArray,"as.factor(c('a','a','c'))")
@test CategoricalArrays.levels(rcopy(CategoricalArray,"factor(c('a','a','c'))")) == ["a","c"]
@test CategoricalArrays.levels(rcopy(NullableCategoricalArray,"factor(c('a',NA,'c'))")) == ["a","c"]
@test CategoricalArrays.isordered(rcopy(CategoricalArray,"ordered(c('a','a','c'))"))
@test CategoricalArrays.isordered(rcopy(NullableCategoricalArray,"ordered(c('a',NA,'c'))"))
