# strings
rp = RObject("p")
@test isa(rp,RObject{StrSxp})
@test length(rp) == 1
@test rcopy(rp) == "p"
@test isa(rcopy(rp),ASCIIString)
@test rcopy(rp[1]) == "p"
@test isa(rp[1],RObject{CharSxp})

rp = RObject("α")
@test isa(rp,RObject{StrSxp})
@test length(rp) == 1
@test rcopy(rp) == "α"
@test isa(rcopy(rp),UTF8String)

rp = RObject(["p","α"])
@test isa(rp,RObject{StrSxp})
@test length(rp) == 2
@test rcopy(rp) == ["p","α"]
@test rcopy(rp[1]) == "p"

# logical
rl = RObject(false)
@test isa(rl,RObject{LglSxp})
@test length(rl) == 1
@test rcopy(rl) === false
@test rl[1] === convert(Cint,0)

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
rr = RObject(2.0)
@test isa(rr,RObject{RealSxp})
@test length(rr) == 1
@test rcopy(rr) === 2.0
@test rr[1] === 2.0

# complex
rc = RObject(2.0-1.0*im)
@test isa(rc,RObject{CplxSxp})
@test length(rc) == 1
@test rcopy(rc) === 2.0-1.0*im
@test rc[1] === 2.0-1.0*im


rc = RObject(Complex128[2.0-1.0*im,2.0+4.0*im])
@test isa(rc,RObject{CplxSxp})
@test length(rc) == 2






