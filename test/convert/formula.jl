using StatsModels

@test StatsModels.Terms(rcopy(R"y ~ x + (1 | g)")) == StatsModels.Terms(@formula y ~ x + (1 | g))
@test StatsModels.Terms(rcopy(R"y ~ x + (1 | g) + (1 | d)")) == StatsModels.Terms(@formula y ~ x + (1 | g) + (1 | d))
@test StatsModels.Terms(rcopy(R"y ~ (a + b) * c")) == StatsModels.Terms(@formula y ~ (a + b) * c)
@test StatsModels.Terms(rcopy(R"y ~ c : (a + b)")) == StatsModels.Terms(@formula y ~ c & (a + b))

# testing association
@test StatsModels.Terms(rcopy(R"y ~ a + b + c")) == StatsModels.Terms(@formula y ~ a + b + c)
@test StatsModels.Terms(rcopy(R"y ~ a + b * c * d")) == StatsModels.Terms(@formula y ~ a + b * c * d)
@test StatsModels.Terms(rcopy(R"y ~ a : b : c")) == StatsModels.Terms(@formula y ~ a & b & c)
@test StatsModels.Terms(rcopy(R"y ~ a + b : c : d")) == StatsModels.Terms(@formula y ~ a + b & c & d)


@test rcopy(rcall(Symbol("=="), R"y ~ x + (1 | g)", RObject(@formula y ~ x + (1 | g))))
@test rcopy(rcall(Symbol("=="), R"y ~ x + (1 | g) + (1 | d)", RObject(@formula y ~ x + (1 | g) + (1 | d))))
@test rcopy(rcall(Symbol("=="), R"y ~ (a + b) * c", RObject(@formula y ~ (a + b) * c)))
@test rcopy(rcall(Symbol("=="), R"y ~ c * (a + b)", RObject(@formula y ~ c * (a + b))))

# testing association
@test rcopy(rcall(Symbol("=="), R"y ~ a + b + c", RObject(@formula y ~ a + b + c)))
@test rcopy(rcall(Symbol("=="), R"y ~ a + b * c * d", RObject(@formula y ~ a + b * c * d)))
@test rcopy(rcall(Symbol("=="), R"y ~ a : b : c", RObject(@formula y ~ a & b & c)))
@test rcopy(rcall(Symbol("=="), R"y ~ d + a : b : c", RObject(@formula y ~ d + a & b & c)))
