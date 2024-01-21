# Test using Rhome set in Preferences.
#
# If run after `install_conda.jl` in the same enviroment, then it will also test
# dynamically overriding the Rhome variable from the build step via preferences.
#
# This file is meant to be run in an embedded process spawned by installation.jl.
@debug ENV["RCALL_DIR"]

using Pkg
using Base.Filesystem: joinpath

Pkg.add("CondaPkg")
Pkg.add("Libdl")
Pkg.add("Preferences")
Pkg.add("UUIDs")

using CondaPkg, Libdl, Preferences, UUIDs

const RCALL_UUID = UUID("6f49c342-dc21-5d91-9882-a32aef131414")

function locate_libR(Rhome)
    @static if Sys.iswindows()
        libR = joinpath(Rhome, "bin", Sys.WORD_SIZE==64 ? "x64" : "i386", "R.dll")
    else
        libR = joinpath(Rhome, "lib", "libR.$(Libdl.dlext)")
    end
    return libR
end

set_preferences!(CondaPkg, "verbosity" => -1)
CondaPkg.add("r")
target_rhome = joinpath(CondaPkg.envdir(), "lib", "R")
# If RCall is already present, then
# we do NOT re-add RCall here because we're testing against the version already built with Conda
if !haskey(Pkg.dependencies(), RCALL_UUID)
    Pkg.add(;path=ENV["RCALL_DIR"])
end
set_preferences!(RCALL_UUID,
                 "Rhome" => target_rhome, "libR" => locate_libR(target_rhome))
RCall = nothing
RCall = CondaPkg.withenv() do
    Pkg.build("RCall")
    Base.require(Main, :RCall)
end
expected = joinpath("x", ".CondaPkg", "env", "lib", "R")[2:end]
if occursin(expected, RCall.Rhome)
    exit(0)
end
println(stderr, "Wrong RCall used $(RCall.Rhome)")
exit(1)
