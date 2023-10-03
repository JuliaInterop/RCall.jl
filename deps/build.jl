import Conda
@static if Sys.iswindows()
    import WinReg
end

include("setup.jl")

const depfile = joinpath(dirname(@__FILE__), "deps.jl")


try
    conda_provided_r = false

    if isfile(depfile)
        @eval module DepFile; include($depfile); end
    else
        @eval module DepFile; Rhome=libR=""; end
    end

    if !haskey(ENV,"R_HOME") && isdir(DepFile.Rhome) && validate_libR(DepFile.libR)
        Rhome, libR = DepFile.Rhome, DepFile.libR
        if isdefined(DepFile, :conda_provided_r)
            conda_provided_r = DepFile.conda_provided_r
        end
        @info "Using previously configured R at $Rhome with libR in $libR."
    else
        Rhome = get(ENV, "R_HOME", "")
        libR = nothing
        if Rhome == "*"
            # install with Conda
            @info "Installing R via Conda.  To use a different R installation,"*
                " set the \"R_HOME\" environment variable and re-run "*
                "Pkg.build(\"RCall\")."
            conda_provided_r = true
            Conda.add_channel("r")
            Conda.add("r-base>=3.4.0,<5") # greater than or equal to 3.4.0 AND strictly less than 5.0
            Rhome = joinpath(Conda.LIBDIR, "R")
            libR = locate_libR(Rhome)
        elseif Rhome == "_"
            Rhome = ""
        else
            if isempty(Rhome)
                try Rhome = readchomp(`R RHOME`); catch; end
            end
            @static if Sys.iswindows()
                if isempty(Rhome)
                    try Rhome = WinReg.querykey(WinReg.HKEY_LOCAL_MACHINE,
                                                "Software\\R-Core\\R", "InstallPath"); catch; end
                end
                if isempty(Rhome)
                    try Rhome = WinReg.querykey(WinReg.HKEY_CURRENT_USER,
                                                "Software\\R-Core\\R", "InstallPath"); catch; end
                end
            end

            if !isempty(Rhome) && !isdir(Rhome)
                error("R_HOME is not a directory.")
            end

            if !isempty(Rhome)
                libR = locate_libR(Rhome)
            end
        end

        if isempty(Rhome)
            @info (
                "No R installation found. " *
                "You will not be able to import RCall without " *
                "providing values for its preferences Rhome and libR."
            )
            open(depfile, "w") do f
                println(f, "const Rhome = \"\"")
                println(f, "const libR = \"\"")
                println(f, "const conda_provided_r = nothing")
            end
        else
            @info "Using R at $Rhome and libR at $libR."
            if DepFile.Rhome != Rhome || DepFile.libR != libR
                open(depfile, "w") do f
                    println(f, "const Rhome = \"", escape_string(Rhome), '"')
                    println(f, "const libR = \"", escape_string(libR), '"')
                    println(f, "const conda_provided_r = $(conda_provided_r)")
                end
            end
        end
    end
catch
    if isfile(depfile)
        rm(depfile, force=true) # delete on error
    end
    rethrow()
end
