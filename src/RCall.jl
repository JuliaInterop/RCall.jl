module RCall

export inherits,
       install,
       lang1,
       lang2,
       lang3,
       library,
       printValue,
       tryEval
       
if isfile(joinpath(dirname(@__FILE__),"..","deps","deps.jl"))
    include("../deps/deps.jl")
else
    error("RCall not properly installed. Please run Pkg.build(\"RCall\")")
end

using Compat

# R internal name for a pointer to a symbolic expression (SEXPREC) structure
# For the time being we will make it Ptr{Void}.  Later we can create an SEXPREC
# type
typealias SEXP Ptr{Void}

function __init__()
    # first check for R_HOME and other environment variables being defined
    envset = true
    envkeys = ["R_HOME","R_DOC_DIR","R_INCLUDE_DIR","R_SHARE_DIR","LD_LIBRARY_PATH"]
    for kk in envkeys
        if !haskey(ENV,kk)
            envset = false
            break
        end
    end
    if !envset
        vals = split(readall(`Rscript -e 'for (nm in c("R_HOME","R_DOC_DIR","R_INCLUDE_DIR","R_SHARE_DIR","LD_LIBRARY_PATH")) print(Sys.getenv(nm),quote=FALSE)'`))
        for i in 1:length(envkeys)
            ENV[envkeys[i]] = vals[2*i]
        end
    end      
    argv = ["Rembed","--silent"]
    i = ccall((:Rf_initEmbeddedR,libR),Cint,(Cint,Ptr{Ptr{Uint8}}),length(argv),argv)
    i > 0 || error("initEmbeddedR failed")
    global const globalEnv = unsafe_load(cglobal((:R_GlobalEnv,libR),Ptr{Void}),1)
    global const emptyEnv = unsafe_load(cglobal((:R_EmptyEnv,libR),Ptr{Void}),1)
    global const nilValue = unsafe_load(cglobal((:R_NilValue,libR),Ptr{Void}),1)
end

include("Rfuns.jl")
end # module

