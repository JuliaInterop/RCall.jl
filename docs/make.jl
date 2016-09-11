using Documenter, RCall

makedocs(
    modules = [RCall],
    clean   = false,
    format   = Documenter.Formats.HTML,
    sitename = "RCall.jl",
    pages    = Any[
        "Introduction" => "index.md",
        "Installation" => "installation.md",
        "Getting Started" => "gettingstarted.md",
        "Internal" => "internal.md"
    ]
)

deploydocs(
    repo = "github.com/JuliaStats/RCall.jl.git",
    julia  = "0.4",
    target = "build",
    deps = nothing,
    make = nothing
)
