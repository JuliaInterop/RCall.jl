# bool
@test ismissing(rcopy(R"NA"))
v = [true ,true ,missing, false]
r = RObject(v)
@test isna(r, 3)
@test !isna(r, 1)
@test ismissing(rcopy(r)[3])
@test rcopy(r)[1:2] == v[1:2]

# integer
@test ismissing(rcopy(R"as.integer(NA)"))
v = [1 ,2 ,missing, 4]
r = RObject(v)
@test isna(r, 3)
@test !isna(r, 1)
@test ismissing(rcopy(r)[3])
@test rcopy(r)[1:2] == v[1:2]

v = Union{Int32, Missing}[1 ,2 ,missing, 4]
r = RObject(v)
@test isna(r, 3)
@test !isna(r, 1)
@test ismissing(rcopy(r)[3])
@test rcopy(r)[1:2] == v[1:2]

# float
@test ismissing(rcopy(R"as.double(NA)"))
v = [1.0 ,2.0 ,missing, 4.0]
r = RObject(v)
@test isna(r, 3)
@test !isna(r, 1)
@test ismissing(rcopy(r)[3])
@test rcopy(r)[1:2] == v[1:2]

v = Union{Float64, Missing}[1.0 ,2.0 ,missing, 4.0]
r = RObject(v)
@test isna(r, 3)
@test !isna(r, 1)
@test ismissing(rcopy(r)[3])
@test rcopy(r)[1:2] == v[1:2]

#string
@test ismissing(rcopy(R"as.character(NA)"))
v = ["a" ,"b" ,missing, "d"]
r = RObject(v)
@test isna(r, 3)
@test !isna(r, 1)
@test ismissing(rcopy(r)[3])
@test rcopy(r)[1:2] == v[1:2]
