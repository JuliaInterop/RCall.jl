using RCall

@test rcopy(R"sum($[7,1,3])") == sum([7,1,3])

iris = rcopy(:iris)
model =  R"lm(Sepal.Length ~ Sepal.Width,data=$iris)"
@test rcopy(RCall.getClass(model)) == "lm"
@test isapprox(rcopy(R"sum($iris$Sepal.Length)"), sum(iris[Symbol("Sepal.Length")]), rtol=4*eps())

