using Compat

if isdefined(Main, :RCall)
    # The environmental variables can cause conflicts if RCall has already been loaded.
    error("RCall already loaded. Please restart Julia and re-run Pkg.build(\"RCall\")")
end


if OS_NAME == :Windows
    ### Windows
    
    Rlibname = "R."*Libdl.dlext
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
        Rlibh = Libdl.dlopen_e(Rlib)
        if Rlibh == C_NULL
            error("Unable to locate $Rlibname\nSee http://juliastats.github.io/RCall.jl/installation/")
        end

        # use _wputenv to circumvent Win32/POSIX ENV bug, see
        # https://github.com/JuliaLang/julia/issues/11215
        # define HOME to stop R defining it
        deps_code = quote
            const libR = $Rlib
            ccall(:_wputenv,Cint,(Ptr{UInt16},),utf16("PATH="*ENV["PATH"]*";"*$Rlibpath))
            ccall(:_wputenv,Cint,(Ptr{UInt16},),utf16("HOME="*homedir())) 
        end
    end
    
else
    ### OS X and Linux
    
    Rlibname = "libR."*Libdl.dlext
    
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
    Rlibh = Libdl.dlopen_e(Rlib)
    if Rlibh == C_NULL
        error("Unable to locate $Rlibname\nSee http://juliastats.github.io/RCall.jl/installation/")
    end

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

julia_exe = joinpath(JULIA_HOME, Base.julia_exename())

## try loading R, and capture version information
rversionhead = readall(`$julia_exe versioninfo.jl`)
R_VERSION = VersionNumber(split(rversionhead,' ')[3])

if R_VERSION < v"3.2.0"
    error("R installation is out of date. RCall.jl requires at least version 3.2.0.\nSee http://juliastats.github.io/RCall.jl/installation/")
end

open("./deps.jl","a") do io
    println(io, :(const R_VERSION = $R_VERSION))
end
