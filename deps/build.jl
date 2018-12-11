import Conda
@static if Sys.iswindows()
    import WinReg
end

include("setup.jl")

const depfile = joinpath(dirname(@__FILE__), "deps.jl")

try
    if isfile(depfile)
        @eval module DepFile; include($depfile); end
    else
        @eval module DepFile; Rhome=libR=""; end
    end

    if !haskey(ENV,"R_HOME") && isdir(DepFile.Rhome) && validate_libR(DepFile.libR, false)
        Rhome, libR = DepFile.Rhome, DepFile.libR
        @info "Using previously configured R at $Rhome with libR in $libR."
    else
        Rhome = get(ENV, "R_HOME", "")
        if Rhome == "*"
            # install with Conda
            different = "  To use a different R installation, set the \"R_HOME\" environment variable and re-run Pkg.build(\"RCall\")."
            @info "Installing R via Conda.$different"
            Conda.add_channel("r")
            Conda.add("r-base")
            Rhome = joinpath(Conda.LIBDIR, "R")
            libR = locate_libR(Rhome, false)
            isempty(libR) && error("Conda R installation failed.$different")
        else
            if isempty(Rhome)
                try Rhome = readchomp(`R RHOME`); catch; end
            end
            @static if Sys.iswindows()
                if isempty(Rhome)
                    try Rhome = WinReg.querykey(WinReg.HKEY_LOCAL_MACHINE,
                                                "Software\\R-Core\\R", "InstallPath"); catch; end
                end
            else
                if !isdir(Rhome)
                    error("R_HOME is not a directory.")
                end
            end
        end
        # libR = isempty(Rhome) ? "" : locate_libR(Rhome, false)
        # if isempty(libR)
        #     if get(ENV, "R_HOME", "") == "*"
        #         different = "  To use a different R installation, set the \"R_HOME\" environment variable and re-run Pkg.build(\"RCall\")."
        #         @info "Installing R via Conda.$different"
        #         Conda.add_channel("r")
        #         Conda.add("r-base")
        #         Rhome = joinpath(Conda.LIBDIR, "R")
        #         libR = locate_libR(Rhome, false)
        #         isempty(libR) && error("Conda R installation failed.$different")
        #     else
        #         error("Fail to use R at $Rhome.")
        #     end
        # end

        @info "Using R at $Rhome and libR at $libR."
        if DepFile.Rhome != Rhome || DepFile.libR != libR
            open(depfile, "w") do f
                println(f, "const Rhome = \"", escape_string(Rhome), '"')
                println(f, "const libR = \"", escape_string(libR), '"')
            end
        end
    end
catch
    if isfile(depfile)
        rm(depfile, force=true) # delete on error
    end
    rethrow()
end
