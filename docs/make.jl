using Lapidary, RCall

# Build documentation.
# ====================

makedocs(
    # options
    modules = [RCall],
    clean   = true
)

# Needs to install an additional dep, mkdocs-material, so provide a custom `deps`.
custom_deps() = run(`pip install --user pygments mkdocs mkdocs-material`)

deploydocs(
    # options
    deps = custom_deps,
    repo = "github.com/JuliaStats/RCall.jl.git"
)
