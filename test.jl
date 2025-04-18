using Pkg
using PrecompileTools, Preferences
set_preferences!(PrecompileTools, "precompile_workloads" => false; force=true)
Pkg.update()
Pkg.test()

