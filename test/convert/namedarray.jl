using NamedArrays

# NamedArray
aa = rcopy(NamedArray, R"Titanic")
@test size(aa) == (4, 2, 2, 2)
@test length(names(aa)[1]) == 4
@test_throws ErrorException rcopy(NamedArray, R"c(1,1)")
@test names(getattrib(RObject(aa), :dimnames))[1] == :Class
