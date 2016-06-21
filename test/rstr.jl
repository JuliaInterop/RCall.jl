using RCall

@test RCall.parse_rscript("x = 1")[3] == 1

@test RCall.parse_rscript("x = 'α'")[3] == 1

@test RCall.parse_rscript("x = \$y")[3] == 1

@test RCall.parse_rscript("x = \$(rand(1))")[3] == 1

@test contains(RCall.parse_rscript("x = 'α'; x = \$y")[4], "not supported")

@test RCall.parse_rscript("x = ]")[4] == "unexpected ']'"

@test RCall.parse_rscript("x = ")[4] == "unexpected end of input"

@test rcopy(R"sum($[7,1,3])") == sum([7,1,3])

iris = rcopy(:iris)
model =  R"lm(Sepal.Length ~ Sepal.Width,data=$iris)"
@test rcopy(RCall.getClass(model)) == "lm"
@test isapprox(rcopy(R"sum($iris$Sepal.Length)"), sum(iris[Symbol("Sepal.Length")]), rtol=4*eps())
