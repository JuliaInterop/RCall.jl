using Compat
import Conda
@static if Compat.Sys.iswindows()
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
        info("Using previously configured R at $Rhome with libR in $libR.")
    else
        Rhome = get(ENV, "R_HOME", "")
        if isempty(Rhome)
            try Rhome = readchomp(`R RHOME`); end
        end
        @static if Compat.Sys.iswindows()
            if isempty(Rhome)
                try Rhome = WinReg.querykey(WinReg.HKEY_LOCAL_MACHINE,
                                            "Software\\R-Core\\R", "InstallPath"); end
            end
        end
        libR = isempty(Rhome) || !isdir(Rhome) ? "" : locate_libR(Rhome, false)
        if isempty(libR)
            different = "  To use a different R installation, set the \"R_HOME\" environment variable and re-run Pkg.build(\"RCall\")."
            info("Installing R via Conda.$different")
            Conda.add_channel("conda-forge")
            Conda.add("r-base")
            Rhome = joinpath(Conda.LIBDIR, "R")
            libR = locate_libR(Rhome, false)
            isempty(libR) && error("Conda R installation failed.$different")
        end

        info("Using R at $Rhome and libR at $libR.")
        if DepFile.Rhome != Rhome || DepFile.libR != libR
            open(depfile, "w") do f
                println(f, "const Rhome = \"", escape_string(Rhome), '"')
                println(f, "const libR = \"", escape_string(libR), '"')
            end
        end
    end
catch
    rm(depfile, force=true) # delete on error
    rethrow()
end
