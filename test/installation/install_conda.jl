# Test installation of RCall when R is not present on the system and R_HOME="*",
# which leads to the autoinstallation of Conda.jl and R via Conda.jl
#
# This file is meant to be run in an embedded process spawned by installation.jl.
@debug ENV["RCALL_DIR"]

using Pkg

# workaround for
# https://stackoverflow.com/questions/75489624/dockerfile-problem-with-miniconda-on-arm64-macos
@static if Sys.isapple() && success(`md5sum $(@__FILE__)`)
    try
        run(`md5 $(@__FILE__)`)
    catch ex
        ex isa IOError || rethrow()
        run(`ln -s "$which" md5sum /bin/md5`)
    end
end

ENV["R_HOME"] = "*"
Pkg.add(;path=ENV["RCALL_DIR"])
Pkg.build("RCall")

RCall = Base.require(Main, :RCall)
if occursin(r"/conda/3/([^/]+/)?lib/R", RCall.Rhome)
    exit(0)
end
println(stderr, "Wrong Conda Rhome $(rcall.Rhome)")
exit(1)
