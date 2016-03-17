using Base.Test
hd = homedir()
pd = Pkg.dir()

using RCall

# https://github.com/JuliaStats/RCall.jl/issues/68
@test hd == homedir()
@test pd == Pkg.dir()

tests = ["basic",
         "conversion",
         "dataframe",
         "rstr"]

println("Running tests:")

for t in tests
    tfile = string(t, ".jl")
    println(" * $(tfile) ...")
    include(tfile)
end

#More tests
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
function funk(x,y)
    x+y
end
f1 = RObject(funk)
@test rcopy(Function, f1)(1,2) == 3
@test rcopy(Function, f1.p)(1,2) == 3
#RCall.rlang_formula(parse("a+b"))
@test RCall.rlang_formula(:a) == :a

#Dictionaries
d = RObject(Dict(1=>2))
@test Dict{Any,Any}("1" => 2) == rcopy(Dict, d)
@test Dict{Int,Int}(1=>2) == rcopy(Dict{Int,Int}, d)

# library
# Since @rimport and @rlibrary create module objects which may be conflict with other objects,
# it is safer to place them at the end of the test.
@rimport MASS as mass
@test_approx_eq rcopy(rcall(mass.ginv, RObject([1 2; 0 4]))) [1 -0.5; 0 0.25]
@rlibrary MASS
@test_approx_eq rcopy(rcall(ginv, RObject([1 2; 0 4]))) [1 -0.5; 0 0.25]
