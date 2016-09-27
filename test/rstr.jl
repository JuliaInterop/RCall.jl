using RCall

@test RCall.render("x = 1")[3] == 1

@test RCall.render("x = 'α'")[3] == 1

@test RCall.render("x = \$y")[3] == 1

@test RCall.render("x = \$(rand(1))")[3] == 1

@test RCall.render("x = \$α")[2]["α"] == :α

@test RCall.render("x = ]")[4] == "unexpected ']'"

@test RCall.render("x = \$(begin")[3] == 2

@test RCall.render("x = \$(begin)")[3] == 3

@test RCall.render("x = ")[4] == "unexpected end of input"

@test rcopy(R"sum($[7,1,3])") == sum([7,1,3])

iris = rcopy(:iris)
model =  R"lm(Sepal.Length ~ Sepal.Width,data=$iris)"
@test rcopy(RCall.getclass(model)) == "lm"
@test isapprox(rcopy(R"sum($iris$Sepal.Length)"), sum(iris[Symbol("Sepal.Length")]), rtol=4*eps())
