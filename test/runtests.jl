using RCall
using Base.Test,DataArrays,DataFrames

lsv = reval("ls()")
@test length(lsv) == 0
@test isa(lsv, RCall.StrSxp)

lsd = reval("ls(\"package:datasets\")")
@test isa(lsv, RCall.StrSxp)
@test length(lsd) == 103
@test rcopy(lsd[2]) == "airmiles"

v110 = DataArray(reval("x <- 1:10"))
@test isa(v110,DataVector)
@test eltype(v110) == Cint

attenu = DataFrame(:attenu)
@test isa(attenu,DataFrame)
@test size(attenu) == (182,5)

dist = attenu[:dist]
@test isa(dist,DataArray{Float64})

psexp = sexp("p")
@test isa(psexp,RCall.StrSxp)
@test length(psexp) == 1
@test rcopy(psexp[1]) == "p"

pqsexp = sexp(["p","q"])
@test isa(pqsexp,RCall.StrSxp)
@test length(pqsexp) == 2
@test rcopy(pqsexp[1]) == "p"
