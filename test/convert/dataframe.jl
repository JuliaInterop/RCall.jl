using DataFrames
using CategoricalArrays

# DataFrame
attenu = rcopy(DataFrame,reval(:attenu))
@test isa(attenu,DataFrame)
@test size(attenu) == (182,5)
@test rcopy(rcall(:dim,RObject(attenu))) == [182,5]
@test rcopy(rcall(:dim, RObject(attenu[1:2, :]))) == [2, 5]
@test rcopy(rcall(:dim, RObject(view(attenu, 1:2, :)))) == [2, 5]
dist = attenu[!, :dist]
@test isa(dist,Array{Float64})
station = attenu[!, :station]
@test isa(station, CategoricalArray)

# single row dataframe
@test size(rcopy(R"data.frame(a=1,b=2)")) == (1, 2)

# issue #186
df = R"""data.frame(dates = as.Date(c("2017-04-14", "2014-04-17")))"""
@test eltype(rcopy(df)[!, :dates]) == Date

# issue #290
R"a = data.frame(a1 = rep(1,3)); a$a2 = matrix(2,3,1)"
R"b = data.frame(a1 = rep(1,3)); b$a2 = rep(2,3)"
@test rcopy(R"a") == rcopy(R"b")

# issue 355
db = DataFrame(x = [missing,missing,missing]);
db = RObject(db);
@test rcopy(R"class($(db)[,1])") == "logical"

