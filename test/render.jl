using RCall

@test RCall.render("x = 1")[1] == "x = 1"

@test RCall.render("x = 'β'")[1] == "x = 'β'"

@test RCall.render("x = \$y")[1] == "x = `#JL`\$`y`"

@test RCall.render("x = \$(rand(1))")[2]["(rand(1))"] == :(rand(1))

@test RCall.render("x = \$β")[2]["β"] == :β

@test_throws RCall.RParseError RCall.render("x = ]")

@test_throws RCall.RParseIncomplete RCall.render("x = \$(begin")

@test_throws ParseError RCall.render("x = \$(begin)")

@test_throws RCall.RParseIncomplete RCall.render("x = ")

@test RCall.render("x = 1\ny = \$a")[1] == "x = 1\ny = `#JL`\$`a`"

@test RCall.render("x = 1\nβ = \$a")[1] == "x = 1\nβ = `#JL`\$`a`"

@test rcopy(R"sum($[7,1,3])") == sum([7,1,3])
