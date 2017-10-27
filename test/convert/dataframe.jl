using DataFrames

# DataFrame
attenu = rcopy(DataFrame,reval(:attenu))
@test isa(attenu,DataFrame)
@test size(attenu) == (182,5)
@test rcopy(rcall(:dim,RObject(attenu))) == [182,5]
@test rcopy(rcall(:dim, RObject(attenu[1:2, :]))) == [2, 5]
@test rcopy(rcall(:dim, RObject(view(attenu, 1:2)))) == [2, 5]
dist = attenu[:dist]
@test isa(dist,DataArray{Float64})
station = attenu[:station]
@test isa(station,PooledDataArray)

# issue #186
df = R"""data.frame(dates = as.Date(c("2017-04-14", "2014-04-17")))"""
if Pkg.installed("DataArrays") < v"0.7"
    @test eltype(rcopy(df)[:dates]) == Date
else
    @test eltype(rcopy(df)[:dates]) == Union{Date, Null}
end
