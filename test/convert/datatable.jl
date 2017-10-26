# using DataTables
using NullableArrays, CategoricalArrays


# DataTable
# attenu = rcopy(DataTable,reval(:attenu))
# @test isa(attenu,DataTable)
# @test size(attenu) == (182,5)
# @test rcopy(rcall(:dim,RObject(attenu))) == [182,5]
# @test rcopy(rcall(:dim, RObject(attenu[1:2, :]))) == [2, 5]
# @test rcopy(rcall(:dim, RObject(view(attenu, 1:2)))) == [2, 5]
# dist = attenu[:dist]
# @test isa(dist,NullableArray{Float64})
# station = attenu[:station]
# @test isa(station,NullableCategoricalArray)


# Nullable
@test isequal(rcopy(Nullable, RObject(1)), Nullable(1))
@test isequal(rcopy(Nullable, RObject("abc")), Nullable("abc"))
@test rcopy(RObject(Nullable(1))) == 1
@test isnull(rcopy(Nullable, RObject(@compat Nullable(1, false))))

# NullableArrays
v110 = rcopy(NullableArray,reval("c(1L, NA)"))
@test isa(v110,NullableVector)
@test eltype(v110) == Nullable{Int32}
@test isnull(rcopy(NullableArray, RObject(v110[2]))[1])

# bool
v = NullableArray([true,true], [true,false])
@test isequal(rcopy(NullableArray,RObject(v)), v)
v = NullableArray([true,true], [false,true])
@test isequal(rcopy(NullableArray,RObject(v)), v)
@test isequal(rcopy(NullableArray,R"c(NA,TRUE)"), NullableArray([true,true], [true,false]))
@test isequal(rcopy(NullableArray,R"c(TRUE, NA)"), NullableArray([true,true], [false,true]))
# int64
v = NullableArray([1,2], [true,false])
@test isequal(rcopy(NullableArray,RObject(v)), v)
v = NullableArray([1,2], [false,true])
@test isequal(rcopy(NullableArray,RObject(v)), v)
@test isequal(rcopy(NullableArray,R"c(NA,1L)"), NullableArray([0,1], [true,false]))
@test isequal(rcopy(NullableArray,R"c(1L,NA)"), NullableArray([1,0], [false,true]))
# int32
v = NullableArray(Int32[1,2], [true,false])
@test isequal(rcopy(NullableArray,RObject(v)), v)
v = NullableArray(Int32[1,2], [false,true])
@test isequal(rcopy(NullableArray,RObject(v)), v)
@test isequal(rcopy(NullableArray,R"c(NA,1L)"), NullableArray(Int32[0,1], [true,false]))
@test isequal(rcopy(NullableArray,R"c(1L,NA)"), NullableArray(Int32[1,0], [false,true]))
# real
v = NullableArray([1.,2.], [true,false])
@test isequal(rcopy(NullableArray,RObject(v)), v)
v = NullableArray([1.,2.], [false,true])
@test isequal(rcopy(NullableArray,RObject(v)), v)
@test isequal(rcopy(NullableArray,R"c(NA,1)"), NullableArray([0,1.], [true,false]))
@test isequal(rcopy(NullableArray,R"c(1,NA)"), NullableArray([1.,0], [false,true]))
# complex
v = NullableArray([0,1.+0*im], [true,false])
@test isequal(rcopy(NullableArray,RObject(v)), v)
v = NullableArray([0,1.+0*im], [false,true])
@test isequal(rcopy(NullableArray,RObject(v)), v)
@test isequal(rcopy(NullableArray,R"c(NA,1+0i)"), NullableArray([0,1.+0*im], [true,false]))
@test isequal(rcopy(NullableArray,R"c(1+0i,NA)"), NullableArray([1.+0*im,0], [false,true]))
# string
v = NullableArray(["","abc"], [true,false])
@test isequal(rcopy(NullableArray,RObject(v)), v)
v = NullableArray(["","abc"], [false,true])
@test isequal(rcopy(NullableArray,RObject(v)), v)
@test isequal(rcopy(NullableArray,R"c(NA,'NA')"), NullableArray(["","NA"], [true,false]))
@test isequal(rcopy(NullableArray,R"c('NA',NA)"), NullableArray(["NA",""], [false,true]))


# CategoricalArrays
v = CategoricalArray(repeat(["a", "b"], inner = 5))
@test isequal(rcopy(CategoricalArray,RObject(v)), v)
v = CategoricalArray(repeat(["a", "b"], inner = 5), ordered=true)
@test isequal(rcopy(CategoricalArray,RObject(v)), v)
@test_throws ErrorException rcopy(NullableArray,R"as.factor(c('a','a','c'))")
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

end
