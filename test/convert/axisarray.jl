using AxisArrays

# AxisArray
aa = rcopy(AxisArray, R"Titanic")
@test size(aa) == (4, 2, 2, 2)
@test length(AxisArrays.axes(aa, 1)) == 4
@test names(getattrib(RObject(aa), :dimnames))[1] == :Class

@test_throws ErrorException rcopy(AxisArray, R"c(1,1)")

s = ["2001-01-01", "1111-11-11", "2012-12-12"]
d = Date.(s)
aa = AxisArray(d, Axis{:time}(["t0", "t2", "t3"]))
r = RObject(aa)
@test rcopy(getclass(r)) == "Date"
@test isa(rcopy(AxisArray, r), AxisArray{Date})
r[2] = missing
ab = rcopy(AxisArray, r)
@test eltype(ab) == Union{Date, Missing}
@test isa(ab.data, Array{Union{Date, Missing}})


a = R"""
a = matrix(0, nr=4, nc=3)
dimnames(a) <- list(NULL, b = LETTERS[1:3])
a
"""
aa = rcopy(AxisArray, a)
@test axisnames(aa) == (:row, :b)
@test AxisArrays.axes(aa,1).val == 1:4
@test AxisArrays.axes(aa,2).val == rcopy(R"LETTERS[1:3]")

a = R"""
a = matrix(0, nr=4, nc=3)
dimnames(a) <- list(a=NULL, b = LETTERS[1:3])
a
"""
aa = rcopy(AxisArray, a)
@test axisnames(aa) == (:a, :b)
@test AxisArrays.axes(aa,1).val == 1:4
@test AxisArrays.axes(aa,2).val == rcopy(R"LETTERS[1:3]")
