using AxisArrays

# AxisArray
aa = rcopy(AxisArray, R"Titanic")
@test size(aa) == (4, 2, 2, 2)
@test length(aa.axes[1]) == 4
@test_throws ErrorException rcopy(AxisArray, R"c(1,1)")
@test names(getattrib(RObject(aa), :dimnames))[1] == :Class
