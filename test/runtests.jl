using RCall

using Base.Test,DataArrays,DataFrames

lsv = reval("ls()")
@test length(lsv) == 0
@test isa(lsv, RObject{StrSxp})

lsd = reval("ls(\"package:datasets\")")
@test isa(lsv, RObject{StrSxp})
@test length(lsd) > 50
@test rcopy(lsd[2]) == "airmiles"

v110 = rcopy(DataArray,reval("x <- 1:10"))
@test isa(v110,DataVector)
@test eltype(v110) == Cint

attenu = rcopy(DataFrame,:attenu)
@test isa(attenu,DataFrame)
@test size(attenu) == (182,5)

dist = attenu[:dist]
@test isa(dist,DataArray{Float64})

psexp = RObject("p")
@test isa(psexp,RObject{StrSxp})
@test length(psexp) == 1
@test rcopy(psexp[1]) == "p"

pqsexp = RObject(["p","q"])
@test isa(pqsexp,RObject{StrSxp})
@test length(pqsexp) == 2
@test rcopy(pqsexp[1]) == "p"

@test rcopy(DataArray,"c(NA,TRUE)").na == @data([NA,true]).na
@test rcopy(DataArray,"c(NA,1)").na == @data([NA,1.0]).na
@test rcopy(DataArray,"c(NA,1+0i)").na == @data([NA,1.0+0.0*im]).na
@test rcopy(DataArray,"c(NA,1L)").na == @data([NA,one(Int32)]).na
@test rcopy(DataArray,"c(NA,'NA')").na == @data([NA,"NA"]).na
@test_throws ErrorException rcopy(DataArray,"as.factor(c('a','a','c'))")
@test rcopy(PooledDataArray,"as.factor(c('a','a','c'))").pool == ["a","c"]

@test rcopy(DataArray,RObject(@data([NA,true]))).na == @data([NA,true]).na
@test rcopy(DataArray,RObject(@data([NA,1]))).na == @data([NA,1]).na
@test rcopy(DataArray,RObject(@data([NA,1.]))).na == @data([NA,1.]).na
@test rcopy(DataArray,RObject(@data([NA,1.+0*im]))).na == @data([NA,1.+0*im]).na
@test rcopy(DataArray,RObject(@data([NA,NA,"a","b"]))).na == @data([NA,NA,"a","b"]).na
pda = PooledDataArray(repeat(["a", "b"], inner = [5]))
@test rcopy(PooledDataArray,RObject(pda)).refs == repeat([1,2], inner = [5])

@test rcopy(rcall(:dim,RObject(attenu))) == [182,5]

langsexp = rlang(:solve, RObject([1 2; 0 4]))
@test length(langsexp) == 2
@test rcopy(reval(langsexp)) == [1 -0.5; 0 0.25]
@test rcopy(langsexp[1]) == :solve
langsexp[1] = RObject(:det)
langsexp[2] = RObject([1 2; 0 0])
@test rcopy(reval(langsexp))[1] == 0

rGlobalEnv[:x] = RObject([1,2,3])
rGlobalEnv[:y] = RObject([4,5,6])
@test rcopy(rcall(symbol("+"),:x,:y)) == [5,7,9]

@rimport MASS as mass
@test round(rcopy(rcall(mass.ginv, RObject([1 2; 0 4]))),5) == [1 -0.5; 0 0.25]

# graphics
f = tempname()
rcall(:png,f)
rcall(:plot,1:10)
rcall(symbol("dev.off"))
@test isfile(f)
