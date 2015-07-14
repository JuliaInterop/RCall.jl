using DataArrays,DataFrames

v110 = rcopy(DataArray,reval("x <- 1:10"))
@test isa(v110,DataVector)
@test eltype(v110) == Cint

attenu = rcopy(DataFrame,:attenu)
@test isa(attenu,DataFrame)
@test size(attenu) == (182,5)

dist = attenu[:dist]
@test isa(dist,DataArray{Float64})

@test rcopy(DataArray,reval("c(NA,TRUE)")).na == @data([NA,true]).na
@test rcopy(DataArray,reval("c(NA,1)")).na == @data([NA,1.0]).na
@test rcopy(DataArray,reval("c(NA,1+0i)")).na == @data([NA,1.0+0.0*im]).na
@test rcopy(DataArray,reval("c(NA,1L)")).na == @data([NA,one(Int32)]).na
@test rcopy(DataArray,reval("c(NA,'NA')")).na == @data([NA,"NA"]).na
@test_throws ErrorException rcopy(DataArray,reval("as.factor(c('a','a','c'))"))
@test rcopy(PooledDataArray,reval("as.factor(c('a','a','c'))")).pool == ["a","c"]

@test rcopy(DataArray,RObject(@data([NA,true]))).na == @data([NA,true]).na
@test rcopy(DataArray,RObject(@data([NA,1]))).na == @data([NA,1]).na
@test rcopy(DataArray,RObject(@data([NA,1.]))).na == @data([NA,1.]).na
@test rcopy(DataArray,RObject(@data([NA,1.+0*im]))).na == @data([NA,1.+0*im]).na
@test rcopy(DataArray,RObject(@data([NA,NA,"a","b"]))).na == @data([NA,NA,"a","b"]).na
pda = PooledDataArray(repeat(["a", "b"], inner = [5]))
@test rcopy(PooledDataArray,RObject(pda)).refs == repeat([1,2], inner = [5])

@test rcopy(rcall(:dim,RObject(attenu))) == [182,5]

