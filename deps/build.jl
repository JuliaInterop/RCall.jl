using Compat

function locate_Rhome()
    Rhome = if haskey(ENV,"R_HOME")
        ENV["R_HOME"]
    else
        try
            readchomp(`R RHOME`)
        catch er
            ""
        end
    end
    @static if Compat.Sys.iswindows()
        if Rhome == ""
            Rhome = try
                    WinReg.querykey(WinReg.HKEY_LOCAL_MACHINE, "Software\\R-Core\\R", "InstallPath")
                catch er
                    ""
                end
        end
    end
    if Rhome == "" || !isdir(Rhome)
        error("Could not find R installation. Either set the \"R_HOME\" environmental variable, or ensure the R executable is available in \"PATH\".")
    end
    info("Using R installation at $Rhome")
    Rhome
end

function locate_libR(Rhome)
    @static if Compat.Sys.iswindows()
        libR = joinpath(Rhome, "bin", Sys.WORD_SIZE==64 ? "x64" : "i386", "R.dll")
    else
        libR = joinpath(Rhome, "lib", "libR.$(Libdl.dlext)")
    end
    libR
end

# adopt from PyCall.jl
function writeifchanged(filename, str)
    if !isfile(filename) || read(filename, String) != str
        info(abspath(filename), " has been updated")
        write(filename, str)
    else
        info(abspath(filename), " has not changed")
    end
end

Rhome = locate_Rhome()
libR = locate_libR(Rhome)

writeifchanged("deps.jl", """
const Rhome = "$(escape_string(Rhome))"
const libR = "$(escape_string(libR))"
""")
