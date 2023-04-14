using Documenter, RCall

makedocs(
    sitename = "RCall.jl",
    pages    = [
        "Introduction" => "index.md",
        "Installation" => "installation.md",
        "Getting Started" => "gettingstarted.md",
        "Supported Conversions" => "conversions.md",
        "Custom Conversion" => "custom.md",
        "Eventloop" => "eventloop.md",
        "Known issues" => "known-issues.md",
        "Internal" => "internal.md"
    ]
)

deploydocs(
    repo = "github.com/JuliaInterop/RCall.jl.git",
    push_preview = true,
    deps = nothing,
    make = nothing
)
