using Documenter, RCall

makedocs(modules = [RCall], clean = true)

deploydocs(repo = "github.com/JuliaStats/RCall.jl.git", julia  = "release")
