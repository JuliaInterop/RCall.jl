# date
s = "2012-12-12"
d = Date(s)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == "Date"
@test length(r) == 1
@test size(r) == (1,)
@test rcopy(r) === d
@test rcopy(R"as.Date($s)") == d
@test rcopy(R"identical(as.Date($s), $d)")

s = ["2001-01-01", "1111-11-11", "2012-12-12"]
d = Date.(s)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == "Date"
@test length(r) == length(d)
@test size(r) == size(d)
@test rcopy(r) == d
@test rcopy(R"as.Date($s)") == d
@test rcopy(R"identical(as.Date($s), $d)")

d = Date[]
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == "Date"
@test length(r) == length(d)
@test size(r) == size(d)
@test rcopy(r) == d
@test rcopy("as.Date(character(0))") == Date[]

# nullable date
s = NullableArray(["0001-01-01", "2012-12-12"], [true, false])
d = NullableArray(Date.(s.values), s.isnull)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == "Date"
@test length(r) == length(d)
@test size(r) == size(d)
@test rcopy(r).isnull == d.isnull
@test rcopy(r).values[!d.isnull] == d.values[!d.isnull]
@test rcopy(R"identical(as.Date($s), $d)")
@test rcopy(R"identical(as.character($d), $s)")

s = NullableArray(["0001-01-01"], [true])
d = NullableArray(Date.(s.values), s.isnull)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == "Date"
@test length(r) == length(d)
@test size(r) == size(d)
@test all(rcopy(r).isnull)
@test rcopy(R"identical(as.Date(NA), $d)")
@test rcopy(R"identical(as.character(NA), $s)")


# dateTime
s = "2012-12-12T12:12:12"
d = DateTime(s)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == ["POSIXct", "POSIXt"]
@test rcopy(getattrib(r, "tzone")) == "UTC"
@test length(r) == 1
@test size(r) == (1,)
@test rcopy(r) === d
@test rcopy(R"as.POSIXct($s, 'UTC', '%Y-%m-%dT%H:%M:%S')") == d
@test rcopy(R"identical(as.character($d, '%Y-%m-%dT%H:%M:%S'), $s)")

s = ["2001-01-01T01:01:01", "1111-11-11T11:11:00", "2012-12-12T12:12:12"]
d = DateTime.(s)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == ["POSIXct", "POSIXt"]
@test rcopy(getattrib(r, "tzone")) == "UTC"
@test length(r) == length(d)
@test size(r) == size(d)
@test rcopy(r) == d
@test rcopy(R"as.POSIXct($s, 'UTC', '%Y-%m-%dT%H:%M:%S')") == d
@test rcopy(R"identical(as.character($d, '%Y-%m-%dT%H:%M:%S'), $s)")

d = DateTime[]
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == ["POSIXct", "POSIXt"]
@test rcopy(getattrib(r, "tzone")) == "UTC"
@test length(r) == length(d)
@test size(r) == size(d)
@test rcopy(r) == d
@test rcopy("as.POSIXct(character(0))") == Date[]

# nullable dateTime
s = NullableArray(["0001-01-01", "2012-12-12T12:12:12"], [true, false])
d = NullableArray(DateTime.(s.values), s.isnull)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == ["POSIXct", "POSIXt"]
@test rcopy(getattrib(r, "tzone")) == "UTC"
@test length(r) == length(d)
@test size(r) == size(d)
@test rcopy(r).isnull == d.isnull
@test rcopy(r).values[!d.isnull] == d.values[!d.isnull]
@test rcopy(R"identical(as.POSIXct($s, 'UTC', '%Y-%m-%dT%H:%M:%S'), $d)")
@test rcopy(R"identical(as.character($d, '%Y-%m-%dT%H:%M:%S'), $s)")

s = NullableArray(["0001-01-01"], [true])
d = NullableArray(DateTime.(s.values), s.isnull)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == ["POSIXct", "POSIXt"]
@test rcopy(getattrib(r, "tzone")) == "UTC"
@test length(r) == length(d)
@test size(r) == size(d)
@test all(rcopy(r).isnull)
@test rcopy(R"identical(as.POSIXct(NA_character_, 'UTC'), $d)")
@test rcopy(R"identical(as.character(NA), $s)")
