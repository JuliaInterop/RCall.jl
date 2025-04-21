using Pkg
Pkg.activate(".")
Pkg.update()
using PrecompileTools, Preferences
set_preferences!(PrecompileTools, "precompile_workloads" => false; force=true)
Pkg.build()
Pkg.test()

