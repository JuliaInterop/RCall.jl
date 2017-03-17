using RCall

@test RCall.render("x = 1")[3] == 1

@test RCall.render("x = 'β'")[3] == 1

@test RCall.render("x = \$y")[3] == 1

@test RCall.render("x = \$(rand(1))")[3] == 1

is_windows() || @test RCall.render("x = \$β")[2]["β"] == :β

@test RCall.render("x = ]")[4] == "unexpected ']'"

@test RCall.render("x = \$(begin")[3] == 2

@test RCall.render("x = \$(begin)")[3] == 3

@test RCall.render("x = ")[4] == "unexpected end of input"

@test RCall.render("x = 1\ny = \$a")[3] == 1

is_windows() || @test RCall.render("x = 1\nβ = \$a")[3] == 1

@test rcopy(R"sum($[7,1,3])") == sum([7,1,3])

@test RCall.render("""
x = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
y = \$a
""")[3] == 1

is_windows() || @test RCall.render("""
x = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
y = \$β
""")[3] == 3

iris = rcopy(reval(:iris))
model =  R"lm(Sepal.Length ~ Sepal.Width,data=$iris)"
@test rcopy(RCall.getclass(model)) == "lm"
@test isapprox(rcopy(R"sum($iris$Sepal.Length)"), sum(iris[Symbol("Sepal.Length")]), rtol=4*eps())
