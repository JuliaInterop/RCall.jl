lsv = reval("ls()")
@test length(lsv) == 0
@test isa(lsv, RObject{StrSxp})

lsd = reval("ls(\"package:datasets\")")
@test isa(lsv, RObject{StrSxp})
@test length(lsd) > 50
@test "airmiles" in rcopy(lsd)

langsexp = rlang(:solve, RObject([1 2; 0 4]))
@test length(langsexp) == 2
@test rcopy(reval(langsexp)) == [1 -0.5; 0 0.25]
@test rcopy(langsexp[1]) == :solve
langsexp[1] = RObject(:det)
langsexp[2] = RObject([1 2; 0 0])
@test rcopy(reval(langsexp))[1] == 0

globalEnv[:x] = RObject([1,2,3])
@test rcopy(globalEnv[:x]) == [1,2,3]
globalEnv[:y] = RObject([4,5,6])
@test rcopy(rcall(Symbol("+"),:x,:y)) == [5,7,9]

x = 1:10
@rput x
@rget x
@test isa(x,Vector{Int32})
@test all(x .== 1:10)

y = "foo"
@rput x y::StrSxp
@rget x y::Array{Compat.UTF8String}
@test isa(y,Vector{Compat.UTF8String})
@test y[1] == "foo"

@test sprint(io -> rprint(io,RObject([1,2,3]))) == "[1] 1 2 3\n"

@test_approx_eq rcopy(rcall(:besselI, 1.0, 2.0)) besseli(2.0,1.0)
@test_approx_eq rcopy(rcall(:besselI, 1.0, 2.0, var"expon.scaled"=true)) besselix(2.0,1.0)


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

nullfn() = nothing
@test isa(rcall(nullfn), RObject{NilSxp})

# graphics
RCall.rgui_init()
f = tempname()
rcall(:png,f)
rcall(:plot,1:10)
rcall(Symbol("dev.off"))
@test isfile(f)
@test !RCall.rgui_start(true)
@test_throws ErrorException RCall.rgui_start()
@test RCall.rgui_stop()

# S4 rprint
@test contains(sprint(io ->
rprint(io, reval("""
   setClass("Foo", representation(x = "numeric"))
   foo <- new("Foo", x = 20)
"""))), "An object of class")

# S3 rprint
@test contains(sprint(io ->
rprint(io, reval("""
   print.Bar <- function(x) print("hello")
   bar <- 1
   class(bar) <- "Bar"
   bar
"""))), "hello")

# operators
a = reval("a=c(1,2,3)")
b = reval("b=c(4,5,6)")
@test rcopy(a+b)==rcopy("a+b")
@test rcopy(a-b)==rcopy("a-b")
@test rcopy(a*b)==rcopy("a*b")
@test rcopy(a/b)==rcopy("a/b")
@test rcopy(a^b)==rcopy("a^b")
