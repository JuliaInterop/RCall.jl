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

@test sprint(io -> rprint(io, RObject([1,2,3]))) == "[1] 1 2 3\n"
@test_logs (:warn, "RCall.jl: Warning: hello\n") reval("warning('hello')")
@test_throws RCall.REvalError reval("stop('hello')")


# @test rcopy(rcall(:besselI, 1.0, 2.0)) ≈ besseli(2.0,1.0)
# @test rcopy(rcall(:besselI, 1.0, 2.0, var"expon.scaled"=true)) ≈ besselix(2.0,1.0)

@test isna(R"list(a=1, b=NA)") == [false, true]
@test isna(R"list(a=1, b=NA)", 1) == false
@test isna(R"list(a=1, b=NA)", 2) == true

@test R"list(1,2)"[1] isa RObject
@test_throws BoundsError R"list(1,2)"[3]

@test length(R"mtcars") == 11
@test size(R"mtcars") == (32, 11)

# setindex with missing and nothing
a = R"1:10"
a[2] = missing
@test isna(a, 2)

a = R"c('a', 'b', 'c')"
a[2] = missing
@test isna(a) == [false, true, false]

a = R"list(x=1, y=2)"
a[2] = nothing
@test isnull(a[2])
a[:x] = nothing
@test isnull(a[:x])

env = reval("new.env()")
env[:x] = 1
@test rcopy(env[:x]) == 1
env[:x] = nothing
@test isnull(env[:x])


# rparse
@test_throws RCall.RParseError rparse(raw"'\g'")
@test_throws RCall.RParseError rparse("``")

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
@test occursin("An object of class",
  sprint(io -> rprint(io, reval("""
   setClass("Foo", representation(x = "numeric"))
   foo <- new("Foo", x = 20)
"""))))

# S3 rprint
@test occursin("hello",
  sprint(io -> rprint(io, reval("""
   print.Bar <- function(x) print("hello")
   bar <- 1
   class(bar) <- "Bar"
   bar
"""))))

@test_logs (:warn, "RCall.jl: Warning in print.Bar(x) : hello\n") rprint(reval("""
   print.Bar <- function(x) warning("hello")
   bar <- 1
   class(bar) <- "Bar"
   bar
"""))

@test_throws RCall.REvalError rprint(reval("""
   print.Bar <- function(x) stop("hello")
   bar <- 1
   class(bar) <- "Bar"
   bar
"""))

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
@test isapprox(rcopy(R"sum($iris$Sepal_Length)"), sum(iris[!, :Sepal_Length]), rtol=4*eps())
@test rcopy(R"factor(rep(1,10))") == fill("1",10)
@test rcopy(R"data.frame(a=rep('test',10), stringsAsFactors = TRUE)")[!, :a] == fill("test",10)


R"""
data(iris)
model <- lm(Sepal.Width ~ Petal.Length, iris)
"""
model = rcopy(R"model")
@test typeof(model[:call]) <: Expr

# getclass
@test rcopy(getclass(reval("1"))) == "numeric"
@test rcopy(getclass(reval("1L"))) == "integer"
@test rcopy(getclass(reval("complex(1,2)"))) == "complex"
if Rversion < v"4"
  @test rcopy(getclass(reval("matrix(1)"))) == "matrix"
else
  @test rcopy(getclass(reval("matrix(1)"))) == ["matrix", "array"]
end
@test rcopy(getclass(reval("function(x) x"))) == "function"
@test rcopy(getclass(reval("data.frame(x=1)"))) == "data.frame"
@test rcopy(getclass(reval("quote(zzz)"))) == "name"
