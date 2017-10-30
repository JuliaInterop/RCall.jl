using RCall

@test RCall.render("x = 1")[3] == 1

@test RCall.render("x = 'β'")[3] == 1

@test RCall.render("x = \$y")[3] == 1

@test RCall.render("x = \$(rand(1))")[3] == 1

@test RCall.render("x = \$β")[2]["β"] == :β

@test RCall.render("x = ]")[4] == "unexpected ']'"

@test RCall.render("x = \$(begin")[3] == 2

@test RCall.render("x = \$(begin)")[3] == 3

@test RCall.render("x = ")[4] == "unexpected end of input"

@test RCall.render("x = 1\ny = \$a")[3] == 1

@test RCall.render("x = 1\nβ = \$a")[3] == 1

@test rcopy(R"sum($[7,1,3])") == sum([7,1,3])
