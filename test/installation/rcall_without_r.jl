# Test installation of RCall when R_HOME specifies an invalid R home.
#
# This file is meant to be run in an embedded process spawned by installation.jl.
@debug ENV["RCALL_DIR"]

using Pkg
ENV["R_HOME"] = "_"
Pkg.add(;path=ENV["RCALL_DIR"])
Pkg.build("RCall")

try
  Base.require(Main, :RCall)
catch e
  if !(e isa LoadError)
    @error "Expected LoadError when running RCall but got $e"
    exit(1)
  end
  exit(0)
end
@error "RCall unexpectedly loaded"
exit(1)
