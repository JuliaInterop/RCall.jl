using Documenter, RCall

makedocs(
    modules = [RCall],
    format   = :html,
    sitename = "RCall.jl",
    pages    = [
        "Introduction" => "index.md",
        "Installation" => "installation.md",
        "Getting Started" => "gettingstarted.md",
        "Internal" => "internal.md"
    ]
)

deploydocs(
    repo = "github.com/JuliaInterop/RCall.jl.git",
    target = "build",
    julia  = "0.5",
    deps = nothing,
    make = nothing
)
