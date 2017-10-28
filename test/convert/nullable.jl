using NullableArrays

# Nullable
@test isequal(rcopy(Nullable, RObject(1)), Nullable(1))
@test isequal(rcopy(Nullable, RObject(1.0)), Nullable(1.0))
@test isequal(rcopy(Nullable, RObject("abc")), Nullable("abc"))
@test rcopy(RObject(Nullable(1))) == 1
@test rcopy(RObject(Nullable(1.0))) == 1.0
@test rcopy(RObject(Nullable("abc"))) == "abc"
@test isnull(rcopy(Nullable, RObject(Nullable(1, false))))
@test isnull(rcopy(Nullable, RObject(Nullable(1.0, false))))
@test isnull(rcopy(Nullable, RObject(Nullable("abc", false))))

# NullableArrays
v110 = rcopy(NullableArray,reval("c(1L, NA)"))
@test isa(v110,NullableVector)
@test eltype(v110) == Nullable{Int}
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
