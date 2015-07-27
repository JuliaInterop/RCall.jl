using Base.Test
using RCall

tests = ["basic",
         "conversion",
         "dataframe"]

println("Running tests:")

for t in tests
    tfile = string(t, ".jl")
    println(" * $(tfile) ...")
    include(tfile)
end
