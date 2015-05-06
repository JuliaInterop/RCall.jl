using Compat, BinDeps

if OS_NAME == :Windows
    Rlibname = "R."*BinDeps.shlib_ext
    # First try to open R dll directly: this will work if it is in the PATH
    if Libdl.dlopen_e(Rlibname) != C_NULL
        deps_code = quote
            const libR = $(Rlibname)
        end
    else
        ## look up windows registry for installation path
        # TODO: use the C interface for this.
        Rinstallpath = split(split(readall(`REG QUERY HKLM\\Software\\R-Core\\R /v InstallPath`),"\r\n")[3],"    ")[4]

        Rlibpath = joinpath(Rinstallpath,"bin",WORD_SIZE==64?"x64":"i386")
        Rlib = joinpath(Rlibpath,Rlibname)
        Libdl.dlopen_e(Rlib) == C_NULL && error("Unable to locate $Rlibname\nTry adding location to PATH and re-run Pkg.build(\"RCall\")")

        # We have to circumvent Win32/POSIX ENV bug, see
        # https://github.com/JuliaLang/julia/issues/11215
        deps_code = quote
            const libR = $Rlib
            ccall(:_wputenv,Cint,(Ptr{UInt16},),utf16("PATH="*ENV["PATH"]*";"*$Rlibpath))
        end
    end
else
    Rlibname = "libR."*BinDeps.shlib_ext
    
    if haskey(ENV,"R_HOME")
        Rscript = joinpath(ENV["R_HOME"],"bin","Rscript")
    else
        # assume is in PATH
        Rscript = "Rscript"
    end

    ## additional keys to get from R
    Renvkeys = ["R_HOME","R_DOC_DIR","R_INCLUDE_DIR","R_SHARE_DIR","LD_LIBRARY_PATH"]
    Renv = Dict()
    for k in Renvkeys
        Renv[k] = readall(`$Rscript -e "cat(Sys.getenv('$k'))"`)
    end

    Rlib = joinpath(Renv["R_HOME"],"lib",Rlibname)
    Libdl.dlopen_e(Rlib) == C_NULL && error("Unable to locate $Rlibname\nTry setting R_HOME, and re-run Pkg.build(\"RCall\").")

    deps_code = quote
        const libR = $Rlib
    end
    for k in Renvkeys
        push!(deps_code.args,:(haskey(ENV,$k) || (ENV[$k] = $(Renv[k]))))
    end
end



## Write the deps.jl file
open("./deps.jl","w") do io
    println(io,"# This is an auto-generated file; do not edit\n")
    println(io, deps_code)
end
