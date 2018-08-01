using RCall


x = 1:10
@rput x
@rget x
@test isa(x,Vector{Int})
@test all(x .== 1:10)

y = "foo"
@rput x y
@rget x y::Array{String}
@test isa(y,Vector{String})
@test y[1] == "foo"


@test RCall.render("x = 1")[1] == "x = 1"

@test RCall.render("x = \$y")[1] == "x = `#JL`\$`y`"

@test RCall.render("x = \$(rand(1))")[2]["(rand(1))"] == :(rand(1))

@test_throws RCall.RParseError RCall.render("x = ]")

@test_throws RCall.RParseIncomplete RCall.render("x = \$(begin")

@test_throws Meta.ParseError RCall.render("x = \$(begin)")

@test_throws RCall.RParseIncomplete RCall.render("x = ")

@test RCall.render("x = 1\ny = \$a")[1] == "x = 1\ny = `#JL`\$`a`"

@test rcopy(R"sum($[7,1,3])") == sum([7,1,3])

@test_throws Exception R"""a = $(error("foo"))"""

if rcopy(reval("isTRUE(l10n_info()\$`UTF-8`)"))

@test RCall.render("x = 'β'")[1] == "x = 'β'"

@test RCall.render("x = \$β")[2]["β"] == :β

@test RCall.render("x = 1\nβ = \$a")[1] == "x = 1\nβ = `#JL`\$`a`"

else

@test_throws RCall.RParseError RCall.render("x = \$β")

end
