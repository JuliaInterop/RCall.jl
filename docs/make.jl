using Documenter, RCall

makedocs(
    modules = [RCall],
    format   = :html,
    sitename = "RCall.jl",
    pages    = [
        "Introduction" => "index.md",
        "Installation" => "installation.md",
        "Getting Started" => "gettingstarted.md",
        "Supported Conversions" => "conversions.md",
        "Custom Conversion" => "custom.md",
        "Eventloop" => "eventloop.md",
        "Internal" => "internal.md"
    ]
)

deploydocs(
    repo = "github.com/JuliaInterop/RCall.jl.git",
    target = "build",
    julia  = "0.7",
    deps = nothing,
    make = nothing
)
