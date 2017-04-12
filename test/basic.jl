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
@rget x y::Array{String}
@test isa(y,Vector{String})
@test y[1] == "foo"

@test sprint(io -> rprint(RObject([1,2,3]), stdout=io)) == "[1] 1 2 3\n"
@test contains(sprint(io -> try reval("warning('hello')", stderr=io); end), "hello")
@test contains(sprint(io -> try reval("stop('hello')", stderr=io); end), "hello")
let filename = tempname()
    origin_stderr = STDERR
    open(filename, "w") do io
        redirect_stderr(io)
        reval("warning('hello')")
    end
    open(filename, "r") do io
        @test contains(String(read(io)), "Warning")
    end
    redirect_stderr(origin_stderr)
    rm(filename)
end


@test rcopy(rcall(:besselI, 1.0, 2.0)) ≈ besseli(2.0,1.0)
@test rcopy(rcall(:besselI, 1.0, 2.0, var"expon.scaled"=true)) ≈ besselix(2.0,1.0)

@test isna(R"list(a=1, b=NA)") == [false, true]
@test isna(R"list(a=1, b=NA)", 1) == false
@test isna(R"list(a=1, b=NA)", 2) == true

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
@test isapprox(r[:minimum][1], -pi/2, atol=eps()^0.25)
r = rcall(:optimize,sin,[0,2],maximum=true)
@test isapprox(r[:maximum][1], pi/2, atol=eps()^0.25)

nullfn() = nothing
@test isa(rcall(nullfn), RObject{NilSxp})

# S4 slots
t1 = R"""
track <- setClass("track", slots = c(x="numeric", y="numeric"))
track(x = 1:10, y = 1:10 + rnorm(10))
"""
@test rcopy(t1[:x]) == collect(1:10)
t1[:x] = 2:11
@test rcopy(t1[:x]) == collect(2:11)
@test_throws Exception t1[:x] = "a"

# graphics
RCall.rgui_init()
let f = tempname()
  rcall(:png,f)
  rcall(:plot,1:10)
  rcall(Symbol("dev.off"))
  @test isfile(f)
  rm(f)
  @test !RCall.rgui_start(true)
  @test_throws ErrorException RCall.rgui_start()
  @test RCall.rgui_stop()
end

# S4 rprint
@test contains(sprint(io ->
rprint(reval("""
   setClass("Foo", representation(x = "numeric"))
   foo <- new("Foo", x = 20)
"""), stdout=io)), "An object of class")

# S3 rprint
@test contains(sprint(io ->
rprint(reval("""
   print.Bar <- function(x) print("hello")
   bar <- 1
   class(bar) <- "Bar"
   bar
"""), stdout=io)), "hello")

@test contains(sprint(io ->
rprint(reval("""
   print.Bar <- function(x) warning("hello")
   bar <- 1
   class(bar) <- "Bar"
   bar
"""), stderr=io)), "hello")

@test contains(sprint(io ->
rprint(reval("""
   print.Bar <- function(x) stop("hello")
   bar <- 1
   class(bar) <- "Bar"
   bar
"""), stderr=io)), "hello")

# operators
a = reval("a=c(1,2,3)")
b = reval("b=c(4,5,6)")
@test rcopy(a+b)==rcopy(R"a+b")
@test rcopy(a-b)==rcopy(R"a-b")
@test rcopy(a*b)==rcopy(R"a*b")
@test rcopy(a/b)==rcopy(R"a/b")
@test rcopy(a^b)==rcopy(R"a^b")

# misc
iris = rcopy(reval(:iris))
model =  R"lm(Sepal_Length ~ Sepal_Width,data=$iris)"
@test rcopy(RCall.getclass(model)) == "lm"
@test isapprox(rcopy(R"sum($iris$Sepal_Length)"), sum(iris[:Sepal_Length]), rtol=4*eps())
