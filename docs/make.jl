using Lapidary, RCall

makedocs(modules = [RCall], clean = true)

deploydocs(repo = "github.com/JuliaStats/RCall.jl.git")
