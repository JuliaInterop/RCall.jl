using DataArrays
using NullableArrays

# date
s = "2012-12-12"
d = Date(s)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == "Date"
@test length(r) == 1
@test size(r) == (1,)
@test rcopy(Date, r) === d
@test rcopy(Date, R"as.Date($s)") == d
@test rcopy(R"identical(as.Date($s), $d)")
v = rcopy(Nullable, R"as.Date(NA)")
@test isa(v, Nullable{Date})
@test isnull(v)
v = rcopy(Nullable, R"as.Date($s)")
@test isa(v, Nullable{Date})
@test !isnull(v)


s = ["2001-01-01", "1111-11-11", "2012-12-12"]
d = Date.(s)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == "Date"
@test length(r) == length(d)
@test size(r) == size(d)
@test rcopy(r) == d
@test rcopy(Array, r) == d
@test rcopy(R"as.Date($s)") == d
@test rcopy(R"identical(as.Date($s), $d)")

d = Date[]
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == "Date"
@test isa(rcopy(Array, r), Array{Date})
@test length(r) == length(d)
@test size(r) == size(d)
@test rcopy(r) == d
@test rcopy(R"as.Date(character(0))") == Date[]

# DataArray date
s = DataArray(["0001-01-01", "2012-12-12"], [true, false])
d = DataArray(Date.(s.data), s.na)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == "Date"
@test isa(rcopy(DataArray, r), DataArray{Date})
@test length(r) == length(d)
@test size(r) == size(d)
@test rcopy(r).na == d.na
@test rcopy(r).data[map(!,d.na)] == d.data[map(!,d.na)]
@test rcopy(DataVector, r).data[map(!,d.na)] == d.data[map(!,d.na)]
@test rcopy(DataVector{Date}, r).data[map(!,d.na)] == d.data[map(!,d.na)]
@test rcopy(DataArray, r).data[map(!,d.na)] == d.data[map(!,d.na)]
@test rcopy(DataArray{Date}, r).data[map(!,d.na)] == d.data[map(!,d.na)]
@test rcopy(R"identical(as.Date($s), $d)")
@test rcopy(R"identical(as.character($d), $s)")

s = DataArray(["0001-01-01"], [true])
d = DataArray(Date.(s.data), s.na)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == "Date"
@test isa(rcopy(DataArray, r), DataArray{Date})
@test length(r) == length(d)
@test size(r) == size(d)
@test all(rcopy(DataVector, r).na)
@test all(rcopy(DataVector{Date}, r).na)
@test all(rcopy(DataArray, r).na)
@test all(rcopy(DataArray{Date}, r).na)
@test rcopy(R"identical(as.Date(NA), $d)")
@test rcopy(R"identical(as.character(NA), $s)")


# nullable date
s = NullableArray(["0001-01-01", "2012-12-12"], [true, false])
d = NullableArray(Date.(s.values), s.isnull)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == "Date"
@test isa(rcopy(NullableArray, r), NullableArray{Date})
@test length(r) == length(d)
@test size(r) == size(d)
@test rcopy(NullableArray{Date}, r).isnull == d.isnull
@test rcopy(NullableArray{Date}, r).values[map(!,d.isnull)] == d.values[map(!,d.isnull)]
@test rcopy(NullableArray, r).values[map(!,d.isnull)] == d.values[map(!,d.isnull)]
@test rcopy(R"identical(as.Date($s), $d)")
@test rcopy(R"identical(as.character($d), $s)")

s = NullableArray(["0001-01-01"], [true])
d = NullableArray(Date.(s.values), s.isnull)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == "Date"
@test isa(rcopy(NullableArray, r), NullableArray{Date})
@test length(r) == length(d)
@test size(r) == size(d)
@test all(rcopy(NullableArray, r).isnull)
@test all(rcopy(NullableArray{Date}, r).isnull)
@test rcopy(R"identical(as.Date(NA), $d)")
@test rcopy(R"identical(as.character(NA), $s)")


# dateTime
s = "2012-12-12T12:12:12"
d = DateTime(s)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == ["POSIXct", "POSIXt"]
@test rcopy(getattrib(r, "tzone")) == "UTC"
@test isa(rcopy(DataArray, r), DataArray{DateTime})
@test length(r) == 1
@test size(r) == (1,)
@test rcopy(r) === d
@test rcopy(DateTime, r) === d
@test rcopy(R"as.POSIXct($s, 'UTC', '%Y-%m-%dT%H:%M:%S')") == d
@test rcopy(R"identical(as.character($d, '%Y-%m-%dT%H:%M:%S'), $s)")
v = rcopy(Nullable, R"as.POSIXct(NA, 'UTC', '%Y-%m-%dT%H:%M:%S')")
@test isa(v, Nullable{DateTime})
@test isnull(v)
v = rcopy(Nullable, R"as.POSIXct($s, 'UTC', '%Y-%m-%dT%H:%M:%S')")
@test isa(v, Nullable{DateTime})
@test !isnull(v)

s = ["2001-01-01T01:01:01", "1111-11-11T11:11:00", "2012-12-12T12:12:12"]
d = DateTime.(s)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == ["POSIXct", "POSIXt"]
@test rcopy(getattrib(r, "tzone")) == "UTC"
@test isa(rcopy(Array, r), Array{DateTime})
@test length(r) == length(d)
@test size(r) == size(d)
@test rcopy(r) == d
@test rcopy(Array{DateTime}, r) == d
@test rcopy(R"as.POSIXct($s, 'UTC', '%Y-%m-%dT%H:%M:%S')") == d
@test rcopy(R"identical(as.character($d, '%Y-%m-%dT%H:%M:%S'), $s)")

d = DateTime[]
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == ["POSIXct", "POSIXt"]
@test rcopy(getattrib(r, "tzone")) == "UTC"
@test isa(rcopy(Array, r), Array{DateTime})
@test length(r) == length(d)
@test size(r) == size(d)
@test rcopy(r) == d
@test rcopy(R"as.POSIXct(character(0))") == Date[]

# DataArray dateTime
s = DataArray(["0001-01-01", "2012-12-12T12:12:12"], [true, false])
d = DataArray(DateTime.(s.data), s.na)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == ["POSIXct", "POSIXt"]
@test rcopy(getattrib(r, "tzone")) == "UTC"
@test isa(rcopy(DataArray, r), DataArray{DateTime})
@test length(r) == length(d)
@test size(r) == size(d)
@test rcopy(r).na == d.na
@test rcopy(r).data[map(!,d.na)] == d.data[map(!,d.na)]
@test rcopy(DataVector, r).data[map(!,d.na)] == d.data[map(!,d.na)]
@test rcopy(DataVector{DateTime}, r).data[map(!,d.na)] == d.data[map(!,d.na)]
@test rcopy(DataArray, r).data[map(!,d.na)] == d.data[map(!,d.na)]
@test rcopy(DataArray{DateTime}, r).data[map(!,d.na)] == d.data[map(!,d.na)]
@test rcopy(R"identical(as.POSIXct($s, 'UTC', '%Y-%m-%dT%H:%M:%S'), $d)")
@test rcopy(R"identical(as.character($d, '%Y-%m-%dT%H:%M:%S'), $s)")

s = DataArray(["0001-01-01"], [true])
d = DataArray(DateTime.(s.data), s.na)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == ["POSIXct", "POSIXt"]
@test rcopy(getattrib(r, "tzone")) == "UTC"
@test isa(rcopy(DataArray, r), DataArray{DateTime})
@test length(r) == length(d)
@test size(r) == size(d)
@test all(rcopy(DataVector, r).na)
@test all(rcopy(DataVector{DateTime}, r).na)
@test all(rcopy(DataArray, r).na)
@test all(rcopy(DataArray{DateTime}, r).na)
@test rcopy(R"identical(as.POSIXct(NA_character_, 'UTC'), $d)")
@test rcopy(R"identical(as.character(NA), $s)")


# nullable dateTime
s = NullableArray(["0001-01-01", "2012-12-12T12:12:12"], [true, false])
d = NullableArray(DateTime.(s.values), s.isnull)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == ["POSIXct", "POSIXt"]
@test rcopy(getattrib(r, "tzone")) == "UTC"
@test isa(rcopy(NullableArray, r), NullableArray{DateTime})
@test length(r) == length(d)
@test size(r) == size(d)
@test rcopy(NullableArray{DateTime}, r).isnull == d.isnull
@test rcopy(NullableArray{DateTime}, r).values[map(!,d.isnull)] == d.values[map(!,d.isnull)]
@test rcopy(NullableArray, r).values[map(!,d.isnull)] == d.values[map(!,d.isnull)]
@test rcopy(R"identical(as.POSIXct($s, 'UTC', '%Y-%m-%dT%H:%M:%S'), $d)")
@test rcopy(R"identical(as.character($d, '%Y-%m-%dT%H:%M:%S'), $s)")

s = NullableArray(["0001-01-01"], [true])
d = NullableArray(DateTime.(s.values), s.isnull)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == ["POSIXct", "POSIXt"]
@test rcopy(getattrib(r, "tzone")) == "UTC"
@test isa(rcopy(NullableArray, r), NullableArray{DateTime})
@test length(r) == length(d)
@test size(r) == size(d)
@test all(rcopy(NullableArray{DateTime}, r).isnull)
@test rcopy(R"identical(as.POSIXct(NA_character_, 'UTC'), $d)")
@test rcopy(R"identical(as.character(NA), $s)")
