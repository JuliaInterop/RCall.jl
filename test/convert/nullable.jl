# Nullable
@test isequal(rcopy(Nullable, RObject(1)), Nullable(1))
@test isequal(rcopy(Nullable, RObject(1.0)), Nullable(1.0))
@test isequal(rcopy(Nullable, RObject("abc")), Nullable("abc"))
@test rcopy(RObject(Nullable(1))) == 1
@test rcopy(RObject(Nullable(1.0))) == 1.0
@test rcopy(RObject(Nullable("abc"))) == "abc"
@test isnull(rcopy(Nullable, RObject(Nullable(1, false))))
@test isnull(rcopy(Nullable, RObject(Nullable(1.0, false))))
@test isnull(rcopy(Nullable, RObject(Nullable("abc", false))))
