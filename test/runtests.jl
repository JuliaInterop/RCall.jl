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
         "rstr",
         "repl"]

println("Running tests:")

for t in tests
    tfile = string(t, ".jl")
    println(" * $(tfile) ...")
    include(tfile)
end


# library
# Since @rimport and @rlibrary create module objects which may be conflict with other objects,
# it is safer to place them at the end of the test.
@rimport MASS as mass
@test_approx_eq rcopy(rcall(mass.ginv, RObject([1 2; 0 4]))) [1 -0.5; 0 0.25]
@rlibrary MASS
@test_approx_eq rcopy(rcall(ginv, RObject([1 2; 0 4]))) [1 -0.5; 0 0.25]
