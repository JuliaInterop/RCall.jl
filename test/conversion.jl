# strings
x = "ppzz!#"
r = RObject(x)
@test isa(r,RObject{StrSxp})
@test length(r) == 1
@test rcopy(r) == x
@test isascii(r)
@test isa(rcopy(r),ASCIIString)
@test rcopy(r[1]) == x
@test isa(r[1],RObject{CharSxp})

x = "aaα₁"
r = RObject(x)
@test isa(r,RObject{StrSxp})
@test length(r) == 1
@test rcopy(r) == x
@test isa(rcopy(r),UTF8String)

v = ["ap","xα⟩","pp"]
r = RObject(v)
@test isa(r,RObject{StrSxp})
@test length(r) == length(v)
@test rcopy(r) == v
@test rcopy(r[1]) == v[1]




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
@test r[1] === convert(Float64,v[1])
@test r[3] === convert(Float64,v[3])

m = Float64[-5 2 9; 7 -8 3]
r = RObject(m)
@test isa(r,RObject{RealSxp})
@test length(r) == length(m)
@test size(r) == size(m)
@test isa(rcopy(r), Matrix{Float64})
@test rcopy(r) == m
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
@test rcopy(r) === convert(Complex128,x)
@test r[1] === convert(Complex128,x)

v = randn(7)+im*randn(7)
r = RObject(v)
@test isa(r,RObject{CplxSxp})
@test length(r) == length(v)
@test size(r) == size(v)
@test isa(rcopy(r), Vector{Complex128})
@test rcopy(r) == collect(v)
@test r[1] === convert(Complex128,v[1])
@test r[3] === convert(Complex128,v[3])

m = Float64[-5 2 9; 7 -8 3] + im*Float64[-5 2 9; 7 -8 3]
r = RObject(m)
@test isa(r,RObject{CplxSxp})
@test length(r) == length(m)
@test size(r) == size(m)
@test isa(rcopy(r), Matrix{Complex128})
@test rcopy(r) == m
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
