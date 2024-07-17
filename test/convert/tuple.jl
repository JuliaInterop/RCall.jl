t = ("a", 1, [1,2])
r = RObject(t)
@test r isa RObject{VecSxp}
@test length(r) == length(t)
@test rcopy(Tuple, r) == t
@test rcopy(typeof(t), r) == t
@test rcopy(r) == t
@test rcopy(Array, r) == collect(t)
r[3] = 2.5
me_test = @test_throws MethodError rcopy(typeof(t), r)
@test me_test.value.f === convert
@test me_test.value.args == (Vector{Int64}, 2.5)

@test rcopy(RObject(sexp(RClass{:list}, t))) isa Vector{Any}
@test rcopy(RObject(t)) isa typeof(t)
