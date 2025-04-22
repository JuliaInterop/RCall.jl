using Pkg
Pkg.UPDATED_REGISTRY_THIS_SESSION[] = true
Pkg.activate(".")
Pkg.update()
using PrecompileTools, Preferences
set_preferences!(PrecompileTools, "precompile_workloads" => false; force=true)
Pkg.update()
Pkg.build()
Pkg.test()

