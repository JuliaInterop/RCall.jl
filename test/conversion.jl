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

# int
ri = RObject(2)
@test isa(ri,RObject{IntSxp})
@test length(ri) == 1
@test rcopy(ri) === convert(Cint,2)
@test ri[1] === convert(Cint,2)

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





