# DataArray

# bool
v = DataArray([true,true], [true,false])
@test isequal(rcopy(DataArray,RObject(v)), v)
v = DataArray([true,true], [false,true])
@test isequal(rcopy(DataArray,RObject(v)), v)
@test isequal(rcopy(DataArray,R"c(NA,TRUE)"), DataArray([true,true], [true,false]))
@test isequal(rcopy(DataArray,R"c(TRUE, NA)"), DataArray([true,true], [false,true]))
@test isa(rcopy(R"c(TRUE, NA)"), DataArray)
# int64
v = DataArray([1,2], [true,false])
@test isequal(rcopy(DataArray,RObject(v)), v)
v = DataArray([1,2], [false,true])
@test isequal(rcopy(DataArray,RObject(v)), v)
@test isequal(rcopy(DataArray,R"c(NA,1L)"), DataArray([0,1], [true,false]))
@test isequal(rcopy(DataArray,R"c(1L,NA)"), DataArray([1,0], [false,true]))
@test isa(rcopy(R"c(1L,NA)"), DataArray)
# int32
v = DataArray(Int32[1,2], [true,false])
@test isequal(rcopy(DataArray,RObject(v)), v)
v = DataArray(Int32[1,2], [false,true])
@test isequal(rcopy(DataArray,RObject(v)), v)
@test isequal(rcopy(DataArray,R"c(NA,1L)"), DataArray(Int32[0,1], [true,false]))
@test isequal(rcopy(DataArray,R"c(1L,NA)"), DataArray(Int32[1,0], [false,true]))
@test isa(rcopy(R"c(1L,NA)"), DataArray)
# real
v = DataArray([1.,2.], [true,false])
@test isequal(rcopy(DataArray,RObject(v)), v)
v = DataArray([1.,2.], [false,true])
@test isequal(rcopy(DataArray,RObject(v)), v)
@test isequal(rcopy(DataArray,R"c(NA,1)"), DataArray([0,1.], [true,false]))
@test isequal(rcopy(DataArray,R"c(1,NA)"), DataArray([1.,0], [false,true]))
@test isa(rcopy(R"c(1,NA)"), DataArray)
# complex
v = DataArray([0,1+0*im], [true,false])
@test isequal(rcopy(DataArray,RObject(v)), v)
v = DataArray([0,1+0*im], [false,true])
@test isequal(rcopy(DataArray,RObject(v)), v)
@test isequal(rcopy(DataArray,R"c(NA,1+0i)"), DataArray([0,1+0*im], [true,false]))
@test isequal(rcopy(DataArray,R"c(1+0i,NA)"), DataArray([1+0*im,0], [false,true]))
@test isa(rcopy(R"c(1+0i,NA)"), DataArray)
# string
v = DataArray(["","abc"], [true,false])
@test isequal(rcopy(DataArray,RObject(v)), v)
v = DataArray(["","abc"], [false,true])
@test isequal(rcopy(DataArray,RObject(v)), v)
@test isequal(rcopy(DataArray,R"c(NA,'NA')"), DataArray(["","NA"], [true,false]))
@test isequal(rcopy(DataArray,R"c('NA',NA)"), DataArray(["NA",""], [false,true]))
@test isa(rcopy(R"c('NA',NA)"), DataArray)
# PooledDataArray
v = PooledDataArray(repeat(["a", "b"], inner = 5))
@test isequal(rcopy(PooledDataArray,RObject(v)), v)
v = PooledDataArray(repeat(["a", "b"], inner = 5), repeat([true, false], outer = 5))
@test isequal(rcopy(PooledDataArray,RObject(v)), v)
@test_throws ErrorException rcopy(DataArray,R"factor(c('a','a','c'))")
@test rcopy(PooledDataArray,R"factor(c('a','a','c'))").pool == ["a","c"]
@test rcopy(PooledDataArray,R"factor(c('a',NA,'c'))").pool == ["a","c"]
@test isa(rcopy(R"factor(c('a',NA,'c'))"), PooledDataArray)
