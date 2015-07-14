lsv = reval("ls()")
@test length(lsv) == 0
@test isa(lsv, RObject{StrSxp})

lsd = reval("ls(\"package:datasets\")")
@test isa(lsv, RObject{StrSxp})
@test length(lsd) > 50
@test rcopy(lsd[2]) == "airmiles"

psexp = RObject("p")
@test isa(psexp,RObject{StrSxp})
@test length(psexp) == 1
@test rcopy(psexp[1]) == "p"

pqsexp = RObject(["p","q"])
@test isa(pqsexp,RObject{StrSxp})
@test length(pqsexp) == 2
@test rcopy(pqsexp[1]) == "p"

langsexp = rlang(:solve, RObject([1 2; 0 4]))
@test length(langsexp) == 2
@test rcopy(reval(langsexp)) == [1 -0.5; 0 0.25]
@test rcopy(langsexp[1]) == :solve
langsexp[1] = RObject(:det)
langsexp[2] = RObject([1 2; 0 0])
@test rcopy(reval(langsexp))[1] == 0

rGlobalEnv[:x] = RObject([1,2,3])
rGlobalEnv[:y] = RObject([4,5,6])
@test rcopy(rcall(symbol("+"),:x,:y)) == [5,7,9]

@rimport MASS as mass
@test round(rcopy(rcall(mass.ginv, RObject([1 2; 0 4]))),5) == [1 -0.5; 0 0.25]

@test sprint(io -> rprint(io,RObject([1,2,3]))) == "[1] 1 2 3\n"

# callbacks
function testfn(x,y;a=3,b=4)
    [x;y;a;b]
end

r = rcall(testfn, 1, 2)
@test isa(r,RObject{IntSxp})
@test rcopy(r) == [1,2,3,4]

r = rcall(testfn, 1, 2,b=6)
@test isa(r,RObject{IntSxp})
@test rcopy(r) == [1,2,3,6]

r = rcall(:optimize,sin,[-2,0])
@test_approx_eq_eps r[:minimum][1] -pi/2 eps()^0.25
r = rcall(:optimize,sin,[0,2],maximum=true)
@test_approx_eq_eps r[:maximum][1] pi/2 eps()^0.25


# graphics
f = tempname()
rcall(:png,f)
rcall(:plot,1:10)
rcall(symbol("dev.off"))
@test isfile(f)
