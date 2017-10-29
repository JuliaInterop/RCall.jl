using AxisArrays

# AxisArray
aa = rcopy(AxisArray, R"Titanic")
@test size(aa) == (4, 2, 2, 2)
@test length(aa.axes[1]) == 4
@test names(getattrib(RObject(aa), :dimnames))[1] == :Class

@test_throws ErrorException rcopy(AxisArray, R"c(1,1)")

s = ["2001-01-01", "1111-11-11", "2012-12-12"]
d = Date.(s)
aa = AxisArray(d, Axis{:time}(["t0", "t2", "t3"]))
r = RObject(aa)
@test rcopy(getclass(r)) == "Date"
@test isa(rcopy(AxisArray, r), AxisArray{Date})
r[2] = null
ab = rcopy(AxisArray, r)
@test isa(ab, AxisArray{Date})
@test isa(ab.data, DataArray)
