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


# SubArray
d = view(d, 1:2)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == "Date"
@test length(r) == length(d)
@test size(r) == size(d)
@test rcopy(r) == d
@test rcopy(Array, r) == d
@test rcopy(R"as.Date($s[1:2])") == d
@test rcopy(R"identical(as.Date($s[1:2]), $d)")


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
@test rcopy(DateTime, r) === d
@test rcopy(R"as.POSIXct($s, 'UTC', '%Y-%m-%dT%H:%M:%S')") == d
# previously the second argument to as.character.POSIXt was `format``, now it defaults
# to `digits`. Using `format` as a named argument gives a deprecation warning
# this changed in R 4.3.0 but is listed as a bugfix
# > as.character(<POSIXt>) now behaves more in line with the methods for atomic vectors such as numbers,
# > and is no longer influenced by options(). Ditto for as.character(<Date>). The as.character() method
# > gets arguments digits and OutDec with defaults not depending on options(). Use of as.character(*, format = .) now warns.
@test rcopy(R"identical(format($d, '%Y-%m-%dT%H:%M:%S'), $s)")


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
@test rcopy(R"identical(format($d, '%Y-%m-%dT%H:%M:%S'), $s)")


# SubArray
d = view(d, 1:2)
r = RObject(d)
@test isa(r,RObject{RealSxp})
@test rcopy(getclass(r)) == ["POSIXct", "POSIXt"]
@test rcopy(getattrib(r, "tzone")) == "UTC"
@test isa(rcopy(Array, r), Array{DateTime})
@test length(r) == length(d)
@test size(r) == size(d)
@test rcopy(r) == d
@test rcopy(Array{DateTime}, r) == d
@test rcopy(R"as.POSIXct($s[1:2], 'UTC', '%Y-%m-%dT%H:%M:%S')") == d
@test rcopy(R"identical(format($d, '%Y-%m-%dT%H:%M:%S'), $s[1:2])")


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
