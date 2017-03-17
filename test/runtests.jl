using NullableArrays,CategoricalArrays,DataFrames,AxisArrays
using Base.Test
hd = homedir()
pd = Pkg.dir()

using RCall

# https://github.com/JuliaStats/RCall.jl/issues/68
@test hd == homedir()
@test pd == Pkg.dir()

tests = ["basic",
         "conversion",
         "data",
         "rstr",
         "library",
         "repl",
         ]

println("Running tests:")

for t in tests
    tfile = string(t, ".jl")
    println(" * $(tfile) ...")
    include(tfile)
end
