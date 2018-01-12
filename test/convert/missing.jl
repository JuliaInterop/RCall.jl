# bool
v = [true ,true ,missing, false]
r = RObject(v)
@test isna(r, 3)
@test !isna(r, 1)
@test ismissing(rcopy(r)[3])
@test rcopy(r)[1:2] == v[1:2]

# integer
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
v = ["a" ,"b" ,missing, "d"]
r = RObject(v)
@test isna(r, 3)
@test !isna(r, 1)
@test ismissing(rcopy(r)[3])
@test rcopy(r)[1:2] == v[1:2]
