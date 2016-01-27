using Base.Test, Compat
hd = homedir()
pd = Pkg.dir()

using RCall
using Compat

# https://github.com/JuliaStats/RCall.jl/issues/68
@test hd == homedir() 
@test pd == Pkg.dir()

tests = ["basic",
         "conversion",
         "dataframe"]

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
@test rcopy(@compat(Int32(1))) == 1
@test rcopy(Cint, @compat(Int32(1))) == 1
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
d = RObject(@compat(Dict(1=>2)))
@test @compat Dict{Any,Any}("1" => 2) == rcopy(Dict, d)
@test @compat Dict{Int,Int}(1=>2) == rcopy(Dict{Int,Int}, d)
