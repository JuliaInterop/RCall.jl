using StatsModels

@test terms(rcopy(R"y ~ x + (1 | g)")) == terms(@formula y ~ x + (1 | g))
@test terms(rcopy(R"y ~ x + (1 | g) + (1 | d)")) == terms(@formula y ~ x + (1 | g) + (1 | d))
@test terms(rcopy(R"y ~ (a + b) * c")) == terms(@formula y ~ (a + b) * c)
@test terms(rcopy(R"y ~ c : (a + b)")) == terms(@formula y ~ c & (a + b))

# testing association
@test terms(rcopy(R"y ~ a + b + c")) == terms(@formula y ~ a + b + c)
@test terms(rcopy(R"y ~ a + b * c * d")) == terms(@formula y ~ a + b * c * d)
@test terms(rcopy(R"y ~ a : b : c")) == terms(@formula y ~ a & b & c)
@test terms(rcopy(R"y ~ a + b : c : d")) == terms(@formula y ~ a + b & c & d)


@test rcopy(rcall(Symbol("=="), R"y ~ x + (1 | g)", RObject(@formula y ~ x + (1 | g))))
@test rcopy(rcall(Symbol("=="), R"y ~ x + (1 | g) + (1 | d)", RObject(@formula y ~ x + (1 | g) + (1 | d))))
@test rcopy(rcall(Symbol("=="), R"y ~ a + b + c + a:c + b:c", RObject(@formula y ~ (a + b) * c)))
@test rcopy(rcall(Symbol("=="), R"y ~ c + a + b + c:a + c:b", RObject(@formula y ~ c * (a + b))))

# testing association
@test rcopy(rcall(Symbol("=="), R"y ~ a + b + c", RObject(@formula y ~ a + b + c)))
@test rcopy(rcall(Symbol("=="), R"y ~ a + b + c + d + b:c + b:d + c:d + b:c:d", RObject(@formula y ~ a + b * c * d)))
@test rcopy(rcall(Symbol("=="), R"y ~ a : b : c", RObject(@formula y ~ a & b & c)))
@test rcopy(rcall(Symbol("=="), R"y ~ d + a : b : c", RObject(@formula y ~ d + a & b & c)))
