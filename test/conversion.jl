using NullableArrays


# strings
x = "ppzz!#"
r = RObject(x)
@test isa(r,RObject{StrSxp})
@test length(r) == 1
@test rcopy(r) == x
@test isascii(r)
@test isascii(rcopy(r))
@test rcopy(r[1]) == x
@test isa(r[1],RObject{CharSxp})

x = "aaα₁"
r = RObject(x)
@test isa(r,RObject{StrSxp})
@test length(r) == 1
@test rcopy(r) == x
@test !isascii(rcopy(r))
@test rcopy(Symbol, r) == Symbol(x)


v = ["ap","xα⟩","pp"]
r = RObject(v)
@test isa(r,RObject{StrSxp})
@test length(r) == length(v)
@test rcopy(r) == v
@test rcopy(r[1]) == v[1]
@test rcopy(Array, r)[1] == v[1]
@test rcopy(Vector, r)[1] == v[1]
@test rcopy(Array{String}, r)[2] == v[2]
@test rcopy(Array{Symbol}, r)[2] == Symbol(v[2])
@test isa(RCall.sexp(StrSxp, :a), Ptr{StrSxp})


# logical
r = RObject(false)
@test isa(r,RObject{LglSxp})
@test length(r) == 1
@test rcopy(r) === false
@test r[1] === convert(Cint,0)

v = bitrand(10)
r = RObject(v)
@test isa(r,RObject{LglSxp})
@test length(r) == length(v)
@test size(r) == size(v)
@test rcopy(r) == v
@test rcopy(Vector, r) == v
@test rcopy(Array, r) == v
@test r[1] === convert(Cint,v[1])


# integer
x = 7
r = RObject(x)
@test isa(r,RObject{IntSxp})
@test length(r) == 1
@test size(r) == (1,)
@test rcopy(r) === convert(Cint,x)
@test r[1] === convert(Cint,x)

v = -7:3
r = RObject(v)
@test isa(r,RObject{IntSxp})
@test length(r) == length(v)
@test size(r) == size(v)
@test isa(rcopy(r), Vector{Cint})
@test rcopy(r) == collect(v)
@test rcopy(Vector, r) == collect(v)
@test r[1] === convert(Cint,v[1])
@test r[3] === convert(Cint,v[3])
r[2] = -100
@test r[2] === convert(Cint,-100)
@test r[1] === convert(Cint,v[1])
@test r[3] === convert(Cint,v[3])


m = Int[-5 2 9; 7 -8 3]
r = RObject(m)
@test isa(r,RObject{IntSxp})
@test length(r) == length(m)
@test size(r) == size(m)
@test isa(rcopy(r), Matrix{Cint})
@test rcopy(r) == m
@test rcopy(Array, r) == m
@test r[1] === convert(Cint,m[1])
@test r[3] === convert(Cint,m[3])
@test r[2,2] === convert(Cint,m[2,2])
r[2] = -100
@test r[2] === convert(Cint,-100)
r[1,3] = -101
@test r[1,3] === convert(Cint,-101)


a = rand(-20:20,2,4,5)
r = RObject(a)
@test isa(r,RObject{IntSxp})
@test length(r) == length(a)
@test size(r) == size(a)
@test isa(rcopy(r), Array{Cint,3})
@test rcopy(r) == a
@test r[1] === convert(Cint,a[1])
@test r[3] === convert(Cint,a[3])
@test r[2,3,2] === convert(Cint,a[2,3,2])

a = rand(-20:20,2,4,2,3)
r = RObject(a)
@test isa(r,RObject{IntSxp})
@test length(r) == length(a)
@test size(r) == size(a)
@test isa(rcopy(r), Array{Cint,4})
@test rcopy(r) == a
@test r[1] === convert(Cint,a[1])
@test r[3] === convert(Cint,a[3])
@test r[2,3,1,2] === convert(Cint,a[2,3,1,2])


# real
x = 7.0
r = RObject(x)
@test isa(r,RObject{RealSxp})
@test length(r) == 1
@test size(r) == (1,)
@test rcopy(r) === convert(Float64,x)
@test r[1] === convert(Float64,x)

v = -7.0:3.0
r = RObject(v)
@test isa(r,RObject{RealSxp})
@test length(r) == length(v)
@test size(r) == size(v)
@test isa(rcopy(r), Vector{Float64})
@test rcopy(r) == collect(v)
@test rcopy(Vector, r) == collect(v)
@test r[1] === convert(Float64,v[1])
@test r[3] === convert(Float64,v[3])

m = Float64[-5 2 9; 7 -8 3]
r = RObject(m)
@test isa(r,RObject{RealSxp})
@test length(r) == length(m)
@test size(r) == size(m)
@test isa(rcopy(r), Matrix{Float64})
@test rcopy(r) == m
@test rcopy(Array, r) == m
@test r[1] === convert(Float64,m[1])
@test r[3] === convert(Float64,m[3])
@test r[2,2] === convert(Float64,m[2,2])

a = rand(2,4,5)
r = RObject(a)
@test isa(r,RObject{RealSxp})
@test length(r) == length(a)
@test size(r) == size(a)
@test isa(rcopy(r), Array{Float64,3})
@test rcopy(r) == a
@test r[1] === convert(Float64,a[1])
@test r[3] === convert(Float64,a[3])
@test r[2,3,2] === convert(Float64,a[2,3,2])

a = rand(2,4,2,3)
r = RObject(a)
@test isa(r,RObject{RealSxp})
@test length(r) == length(a)
@test size(r) == size(a)
@test isa(rcopy(r), Array{Float64,4})
@test rcopy(r) == a
@test r[1] === convert(Float64,a[1])
@test r[3] === convert(Float64,a[3])
@test r[2,3,1,2] === convert(Float64,a[2,3,1,2])

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


# complex
x = 7.0-2.0*im
r = RObject(x)
@test isa(r,RObject{CplxSxp})
@test length(r) == 1
@test size(r) == (1,)
@test rcopy(r) === convert(Complex128,x)
@test r[1] === convert(Complex128,x)

v = randn(7)+im*randn(7)
r = RObject(v)
@test isa(r,RObject{CplxSxp})
@test length(r) == length(v)
@test size(r) == size(v)
@test isa(rcopy(r), Vector{Complex128})
@test rcopy(r) == collect(v)
@test rcopy(Vector, r) == collect(v)
@test r[1] === convert(Complex128,v[1])
@test r[3] === convert(Complex128,v[3])

m = Float64[-5 2 9; 7 -8 3] + im*Float64[-5 2 9; 7 -8 3]
r = RObject(m)
@test isa(r,RObject{CplxSxp})
@test length(r) == length(m)
@test size(r) == size(m)
@test isa(rcopy(r), Matrix{Complex128})
@test rcopy(r) == m
@test rcopy(Array, r) == m
@test r[1] === convert(Complex128,m[1])
@test r[3] === convert(Complex128,m[3])
@test r[2,2] === convert(Complex128,m[2,2])

a = rand(2,4,5)+im*randn(2,4,5)
r = RObject(a)
@test isa(r,RObject{CplxSxp})
@test length(r) == length(a)
@test size(r) == size(a)
@test isa(rcopy(r), Array{Complex128,3})
@test rcopy(r) == a
@test r[1] === convert(Complex128,a[1])
@test r[3] === convert(Complex128,a[3])
@test r[2,3,2] === convert(Complex128,a[2,3,2])

a = rand(2,4,2,3)+im*randn(2,4,2,3)
r = RObject(a)
@test isa(r,RObject{CplxSxp})
@test length(r) == length(a)
@test size(r) == size(a)
@test isa(rcopy(r), Array{Complex128,4})
@test rcopy(r) == a
@test r[1] === convert(Complex128,a[1])
@test r[3] === convert(Complex128,a[3])
@test r[2,3,1,2] === convert(Complex128,a[2,3,1,2])

# dict
d = Dict(:a=>[1, 2, 4], :b=> ["e", "d", "f"])
r = RObject(d)
@test r[:a][3] == 4
@test rcopy(r[:b][2]) == "d"
l = rcopy("list(a=1,b=c(1,3,4))")
@test l[:a] == 1
@test l[:b][3] == 4
d = RObject(Dict(1=>2))
@test Dict{Any,Any}("1" => 2) == rcopy(Dict, d)
@test Dict{Int,Int}(1=>2) == rcopy(Dict{Int,Int}, d)


# function
function funk(x,y)
    x+y
end
f1 = RObject(funk)
@test rcopy(Function, f1)(1,2) == 3
@test rcopy(Function, f1.p)(1,2) == 3


# misc
a = RObject(rand(10))
@test length(rcopy(Any, a)) == 10
@test typeof(RCall.sexp(Cint, 1)) == Cint
@test typeof(RCall.sexp(Float64, 1)) == Float64
@test typeof(RCall.sexp(Complex128, 1)) == Complex128
@test typeof(rcopy(Vector{Float64}, a.p)) == Vector{Float64}
b = RObject(true)
@test rcopy(Int32(1)) == 1
@test rcopy(Cint, Int32(1)) == 1
@test rcopy(Cint, b.p) == 1
@test rcopy(Vector{Cint}, b.p) == [1]
@test rcopy(Array{Cint}, b.p) == [1]
@test rcopy(Vector{Bool}, b.p) == [true]
@test rcopy(BitVector, b.p) == [true]

#RCall.rlang_formula(parse("a+b"))
@test RCall.rlang_formula(:a) == :a
