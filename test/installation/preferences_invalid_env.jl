# Test using Rhome set in Preferences, with invalid R_HOME set at build time.
#
# If run after `install_conda.jl` in the same enviroment, then it will also test
# dynamically overriding the Rhome variable from the build step via preferences.
#
# This file is meant to be run in an embedded process spawned by installation.jl.
@debug ENV["RCALL_DIR"]

using Pkg

Pkg.add("CondaPkg")
Pkg.add("Libdl")
Pkg.add("Preferences")
Pkg.add("UUIDs")

using CondaPkg, Libdl, Preferences, UUIDs

function locate_libR(Rhome)
    @static if Sys.iswindows()
        libR = joinpath(Rhome, "bin", Sys.WORD_SIZE==64 ? "x64" : "i386", "R.dll")
    else
        libR = joinpath(Rhome, "lib", "libR.$(Libdl.dlext)")
    end
    return libR
end

CondaPkg.add("r")
target_rhome = joinpath(CondaPkg.envdir(), "lib", "R")
set_preferences!(UUID("6f49c342-dc21-5d91-9882-a32aef131414"),
                 "Rhome" => target_rhome, "libR" => locate_libR(target_rhome))
ENV["R_HOME"] = "_"
Pkg.add(;path=ENV["RCALL_DIR"])
Pkg.build("RCall")
RCall = Base.require(Main, :RCall)
if occursin("/.CondaPkg/env/lib/R", RCall.Rhome)
    exit(0)
end
println(stderr, "Wrong RCall used $(RCall.Rhome)")
exit(1)
