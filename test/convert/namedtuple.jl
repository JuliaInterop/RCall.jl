nt = (a="a", b=1, c=[1,2])
r = RObject(nt)
@test r isa RObject{VecSxp}
@test length(r) == length(nt)
@test rcopy(NamedTuple, r) == nt
@test rcopy(typeof(nt), r) == nt
r[:c] = 2.5
@test_throws MethodError rcopy(typeof(nt), r)

r = RObject((a="a", d=1))
@test_throws ArgumentError rcopy(typeof(nt), r)
@test_throws ArgumentError rcopy(NamedTuple{(:a,:b,:c)}, r)
@test (rcopy(NamedTuple{(:a,:d)}, r); true)

@test rcopy(RObject(sexp(RClass{:list}, nt))) isa OrderedDict
@test rcopy(RObject(nt)) isa typeof(nt) 
