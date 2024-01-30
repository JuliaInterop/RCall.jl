# Test removal of Rhome from preferences.
#
# If run after `install_conda.jl` and `swap_to_prefs_and_condapkg.jl` in the same enviroment,
# then it tests returning to the build status quo after removal of preferences.
#
# This file is meant to be run in an embedded process spawned by installation.jl.
@debug ENV["RCALL_DIR"]
using Preferences, UUIDs

set_preferences!(UUID("6f49c342-dc21-5d91-9882-a32aef131414"),
                 "Rhome" => nothing, "libR" => nothing; force=true)

RCall = Base.require(Main, :RCall)
if occursin(r"/conda/3/([^/]+/)?lib/R", RCall.Rhome)
    exit(0)
end
println(stderr, "Wrong Conda Rhome $(rcall.Rhome)")
exit(1)
