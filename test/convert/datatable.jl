using DataTables

# DataTable
attenu = rcopy(DataTable,reval(:attenu))
@test isa(attenu,DataTable)
@test size(attenu) == (182,5)
@test rcopy(rcall(:dim,RObject(attenu))) == [182,5]
@test rcopy(rcall(:dim, RObject(attenu[1:2, :]))) == [2, 5]
@test rcopy(rcall(:dim, RObject(view(attenu, 1:2)))) == [2, 5]
dist = attenu[:dist]
@test isa(dist,NullableArray{Float64})
station = attenu[:station]
@test isa(station,NullableCategoricalArray)
