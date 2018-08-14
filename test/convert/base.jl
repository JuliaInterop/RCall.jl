using Random

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
@test isa(RCall.sexp(RCall.RClass{:character}, :a), Ptr{StrSxp})

s = SubString{String}["a","b"]
r = RObject(s)
@test isa(r,RObject{StrSxp})
@test length(r) == length(s)
@test rcopy(r) == s
@test rcopy(r[1]) == s[1]


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
@test rcopy(Int, R"TRUE") == 1
@test rcopy(Int, R"1") == 1
@test rcopy(Array{Int}, R"c(1,2,3)") == [1,2,3]

x = 7
r = RObject(x)
@test isa(r,RObject{IntSxp})
@test length(r) == 1
@test size(r) == (1,)
@test rcopy(r) === x
@test r[1] === convert(Cint,x)


v = -7:3
r = RObject(v)
@test isa(r,RObject{IntSxp})
@test length(r) == length(v)
@test size(r) == size(v)
@test isa(rcopy(r), Vector{Int})
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
@test isa(rcopy(r), Matrix{Int})
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
@test isa(rcopy(r), Array{Int,3})
@test rcopy(r) == a
@test r[1] === convert(Cint,a[1])
@test r[3] === convert(Cint,a[3])
@test r[2,3,2] === convert(Cint,a[2,3,2])

a = rand(-20:20,2,4,2,3)
r = RObject(a)
@test isa(r,RObject{IntSxp})
@test length(r) == length(a)
@test size(r) == size(a)
@test isa(rcopy(r), Array{Int,4})
@test rcopy(r) == a
@test r[1] === convert(Cint,a[1])
@test r[3] === convert(Cint,a[3])
@test r[2,3,1,2] === convert(Cint,a[2,3,1,2])


# real
@test rcopy(Float64, R"TRUE") == 1.0
@test rcopy(Float64, R"1L") == 1.0
@test rcopy(Array{Float64}, R"c(1L,2L,3L)") == [1.0,2.0,3.0]

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

# complex
x = 7.0-2.0*im
r = RObject(x)
@test isa(r,RObject{CplxSxp})
@test length(r) == 1
@test size(r) == (1,)
@test rcopy(r) === convert(ComplexF64,x)
@test r[1] === convert(ComplexF64,x)

v = randn(7)+im*randn(7)
r = RObject(v)
@test isa(r,RObject{CplxSxp})
@test length(r) == length(v)
@test size(r) == size(v)
@test isa(rcopy(r), Vector{ComplexF64})
@test rcopy(r) == collect(v)
@test rcopy(Vector, r) == collect(v)
@test r[1] === convert(ComplexF64,v[1])
@test r[3] === convert(ComplexF64,v[3])

m = Float64[-5 2 9; 7 -8 3] + im*Float64[-5 2 9; 7 -8 3]
r = RObject(m)
@test isa(r,RObject{CplxSxp})
@test length(r) == length(m)
@test size(r) == size(m)
@test isa(rcopy(r), Matrix{ComplexF64})
@test rcopy(r) == m
@test rcopy(Array, r) == m
@test r[1] === convert(ComplexF64,m[1])
@test r[3] === convert(ComplexF64,m[3])
@test r[2,2] === convert(ComplexF64,m[2,2])

a = rand(2,4,5)+im*randn(2,4,5)
r = RObject(a)
@test isa(r,RObject{CplxSxp})
@test length(r) == length(a)
@test size(r) == size(a)
@test isa(rcopy(r), Array{ComplexF64,3})
@test rcopy(r) == a
@test r[1] === convert(ComplexF64,a[1])
@test r[3] === convert(ComplexF64,a[3])
@test r[2,3,2] === convert(ComplexF64,a[2,3,2])

a = rand(2,4,2,3)+im*randn(2,4,2,3)
r = RObject(a)
@test isa(r,RObject{CplxSxp})
@test length(r) == length(a)
@test size(r) == size(a)
@test isa(rcopy(r), Array{ComplexF64,4})
@test rcopy(r) == a
@test r[1] === convert(ComplexF64,a[1])
@test r[3] === convert(ComplexF64,a[3])
@test r[2,3,1,2] === convert(ComplexF64,a[2,3,1,2])

# dict
d = Dict(:a=>[1, 2, 4], :b=> ["e", "d", "f"])
r = RObject(d)
@test r[:a][3] == 4
@test rcopy(r[:b][2]) == "d"
l = rcopy(R"list(a=1,b=c(1,3,4))")
@test l[:a] == 1
@test l[:b][3] == 4
d = RObject(Dict("a"=>2))
@test Dict{Any,Any}("a" => 2) == rcopy(Dict, d)
@test Dict{String,Int}("a"=>2) == rcopy(Dict{String,Int}, d)

# list
a = Any[1, 1:10]
r = RObject(a)
@test isa(r, RObject{VecSxp})
@test isa(rcopy(r), Array{Any})
@test isa(rcopy(Array, r), Array{Any})


# raw
a = 0x01
r = RObject(a)
@test a == rcopy(r)
@test rcopy(UInt8, r) == 0x01

a = UInt8[0x01, 0x0c, 0xff]
r = RObject(a)
@test a == rcopy(r)
@test rcopy(Array, r) == a

# function
function funk(x,y)
    x+y
end
f1 = RObject(funk)
@test rcopy(Function, f1)(1,2) == 3
@test rcopy(Function, f1.p)(1,2) == 3

# misc
@test rcopy(Int32(1)) == 1
@test rcopy(Cint, Int32(1)) == 1
a = RObject(rand(10))
@test length(rcopy(Any, a)) == 10
# @test typeof(RCall.sexp(Cint, 1)) == Cint
# @test typeof(RCall.sexp(Float64, 1)) == Float64
# @test typeof(RCall.sexp(ComplexF64, 1)) == ComplexF64
@test typeof(rcopy(Vector{Float64}, a.p)) == Vector{Float64}
b = RObject(true)
@test rcopy(Cint, b.p) == 1
@test rcopy(Vector{Cint}, b.p) == [1]
@test rcopy(Array{Cint}, b.p) == [1]
@test rcopy(Vector{Bool}, b.p) == [true]
@test rcopy(BitVector, b.p) == [true]
@test isa(convert(Any, R"list(a=1,b=2)"), RObject)
@test isa(convert(RObject{}, R"list(a=1,b=2)"), RObject)

# issue 195
@test isa(rcopy(R"list(a=NULL)")[:a], Nothing)

# convert to Any
@test isa(rcopy(Any, R"1"), Float64)
@test isa(convert(Any, R"1"), RObject)


# s4

@test isa(rcopy(reval("""
   setClass("Foo", representation(x = "numeric"))
   foo <- new("Foo", x = 20)
""")), RObject)
