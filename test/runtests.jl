using RCall
using Base.Test,DataArrays,DataFrames

# write your own tests here
attenu = dataset(:attenu)
@test typeof(attenu) == DataFrame
dist = attenu[:dist]
@test typeof(dist) == DataVector{Float64}

