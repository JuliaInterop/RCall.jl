## Check for values of environment variables expected by R
const envkeys = ["R_HOME","R_DOC_DIR","R_INCLUDE_DIR","R_SHARE_DIR","LD_LIBRARY_PATH"]
if any(x->!haskey(ENV,x), envkeys)
    vals = split(readall(`Rscript -e 'for (nm in c("R_HOME","R_DOC_DIR","R_INCLUDE_DIR","R_SHARE_DIR","LD_LIBRARY_PATH")) print(Sys.getenv(nm),quote=FALSE)'`),'\n')
    for i in 1:length(envkeys)
        ENV[envkeys[i]] = vals[i][5:end]  # first part of each value is "[1] "
    end
end

## Create and test the libR path
const libR = joinpath(ENV["R_HOME"],"lib",string("libR.",Base.Sys.shlib_ext))
dlopen_e(libR) == C_NULL && error("Unable to load $libR\n\nPlease re-run Pkg.build(package), and restart Julia.")

## Write the deps.jl file
open("./deps.jl","w") do io
    println(io,"# This is an auto-generated file; do not edit\n")
    println(io,"const libR=\"",libR,"\"")
    println(io,"ENV[\"R_HOME\"]=\"",ENV["R_HOME"],"\"")
    println(io,"ENV[\"R_DOC_DIR\"]=\"",ENV["R_DOC_DIR"],"\"")
    println(io,"ENV[\"R_INCLUDE_DIR\"]=\"",ENV["R_INCLUDE_DIR"],"\"")
    println(io,"ENV[\"R_SHARE_DIR\"]=\"",ENV["R_SHARE_DIR"],"\"") 
    println(io,"ENV[\"LD_LIBRARY_PATH\"]=\"",ENV["LD_LIBRARY_PATH"],"\"")   
end
