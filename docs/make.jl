using Lapidary, RCall

# Build documentation.
# ====================

makedocs(
    # options
    modules = [RCall],
    clean   = true
)
