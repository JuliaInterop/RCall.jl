using RCall

@test RCall.render_rscript("x = 1")[3] == 1

@test RCall.render_rscript("x = 'α'")[3] == 1

@test RCall.render_rscript("x = \$y")[3] == 1

@test RCall.render_rscript("x = \$(rand(1))")[3] == 1

@test RCall.render_rscript("x = \$α")[2]["α"] == :α

@test RCall.render_rscript("x = ]")[4] == "unexpected ']'"

@test RCall.render_rscript("x = ")[4] == "unexpected end of input"

@test rcopy(R"sum($[7,1,3])") == sum([7,1,3])

iris = rcopy(:iris)
model =  R"lm(Sepal.Length ~ Sepal.Width,data=$iris)"
@test rcopy(RCall.getclass(model)) == "lm"
@test isapprox(rcopy(R"sum($iris$Sepal.Length)"), sum(iris[Symbol("Sepal.Length")]), rtol=4*eps())
