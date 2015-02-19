using RCall
using Base.Test,DataArrays,DataFrames

lsv = reval("ls()")
@test length(lsv) == 0
@test isa(lsv, SEXP{16})

lsd = reval("ls(\"package:datasets\")")
@test isa(lsv, SEXP{16})
@test length(lsd) == 103
@test bytestring(lsd[2]) == "airmiles"

v110 = dataset(reval("x <- 1:10"))
@test isa(v110,DataVector)
@test eltype(v110) == Cint

attenu = dataset(:attenu)
@test isa(attenu,DataFrame)
@test size(attenu) == (182,5)

dist = attenu[:dist]
@test isa(dist,DataArray{Float64})

psexp = sexp("p")
@test isa(psexp,SEXP{16})
@test length(psexp) == 1
@test bytestring(psexp[1]) == "p"

pqsexp = sexp(["p","q"])
@test isa(pqsexp,SEXP{16})
@test length(pqsexp) == 2
@test bytestring(pqsexp[1]) == "p"
