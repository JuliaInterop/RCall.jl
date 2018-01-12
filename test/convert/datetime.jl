using DataArrays
using Compat.Dates

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
@test isa(v, Nullable)
@test isnull(v)
v = rcopy(Nullable, R"as.Date($s)")
@test isa(v, Nullable)
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


# Missing array date
d = [Date("2001-01-01"), missing, Date("2012-12-12")]
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == "Date"
@test length(r) == length(d)
@test size(r) == size(d)
@test rcopy(r)[[1,3]] == d[[1,3]]
@test ismissing(rcopy(r)[2])
@test rcopy(Array, r)[[1,3]] == d[[1,3]]
@test ismissing(rcopy(Array, r)[2])

# DataArray date
s = DataArray(["0001-01-01", "2012-12-12"], [true, false])
d = DataArray(Date.(s.data), s.na)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == "Date"
@test isa(rcopy(DataArray, r), DataArray{Date})
@test length(r) == length(d)
@test size(r) == size(d)
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
@test isa(v, Nullable)
@test isnull(v)
v = rcopy(Nullable, R"as.POSIXct($s, 'UTC', '%Y-%m-%dT%H:%M:%S')")
@test isa(v, Nullable)
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

# Missing array dateTime

# Missing array date
d = [DateTime("2001-01-01T01:01:01"), missing, DateTime("2012-12-12T12:12:12")]
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == ["POSIXct", "POSIXt"]
@test length(r) == length(d)
@test size(r) == size(d)
@test rcopy(r)[[1,3]] == d[[1,3]]
@test ismissing(rcopy(r)[2])
@test rcopy(Array, r)[[1,3]] == d[[1,3]]
@test ismissing(rcopy(Array, r)[2])

# DataArray dateTime
s = DataArray(["2001-01-01T01:01:01", "2012-12-12T12:12:12"], [true, false])
d = DataArray(DateTime.(s.data), s.na)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == ["POSIXct", "POSIXt"]
@test rcopy(getattrib(r, "tzone")) == "UTC"
@test isa(rcopy(DataArray, r), DataArray{DateTime})
@test length(r) == length(d)
@test size(r) == size(d)
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
