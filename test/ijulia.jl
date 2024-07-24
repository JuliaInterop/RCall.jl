using Conda
using IJulia
using RCall
using Weave
using Test

Conda.add("jupyter")
testpath = Base.Fix1(joinpath, @__DIR__)
jupyter_path = joinpath(Conda.BINDIR, "jupyter")
Weave.notebook(testpath("ijulia.jmd"); out_path=@__DIR__, jupyter_path=jupyter_path)

run(`$(jupyter_path) nbconvert $(testpath("ijulia.ipynb")) --to html --embed-images`)
const PNG = """<img alt="No description has been provided for this image" class="" src="data:image/png;base64"""
const SVG = """<img alt="No description has been provided for this image" src="data:image/svg+xml;base64"""
html = read(testpath("ijulia.html"), String)

@test occursin(PNG,  html)
@test occursin(SVG,  html)

# create a folder ijulia_files with the exported images -- could be useful if we ever set up percy
# run(`$(jupyter_path) nbconvert $(testpath("ijulia.ipynb")) --to markdown`)
