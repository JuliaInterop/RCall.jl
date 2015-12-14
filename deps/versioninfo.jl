include("deps.jl")

# print R version header
argv = ["REmbeddedJulia","--version"]
i = ccall((:Rf_initEmbeddedR,libR),Cint,(Cint,Ptr{Ptr{UInt8}}),length(argv),argv)
i > 0 || error("Unable to initialize R.")
ccall((:Rf_endEmbeddedR,libR),Void,(Cint,),0)


