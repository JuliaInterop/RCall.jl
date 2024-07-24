using Conda
using IJulia
using RCall
using Weave
using Test

# $(abspath(dirname(@__DIR__)))
IJulia.installkernel("julia", "--project=@.")
jupyter_path = joinpath(Conda.BINDIR, "jupyter")
if !isfile(jupyter_path)
    Conda.add("jupyter")
end
testpath = Base.Fix1(joinpath, @__DIR__)
Weave.notebook(testpath("ijulia.jmd"); out_path=@__DIR__, jupyter_path=jupyter_path)

run(`$(jupyter_path) nbconvert $(testpath("ijulia.ipynb")) --to html --embed-images`)
const PNG = """<img alt="No description has been provided for this image" class="" src="data:image/png;base64"""
const SVG = """<img alt="No description has been provided for this image" src="data:image/svg+xml;base64"""
html = read(testpath("ijulia.html"), String)

# these are the tests to show that things actually work
@test occursin(PNG,  html)
@test occursin(SVG,  html)

@test_throws ArgumentError("Unsupported MIME type: lulz") RCall.rdevicename(MIME("lulz"))

# create a folder ijulia_files with the exported images -- could be useful if we ever set up percy
# run(`$(jupyter_path) nbconvert $(testpath("ijulia.ipynb")) --to markdown`)

# these are the tests to get code coverage
# nothing like a little piracy when testing in a headless setup
RCall.ijulia_init()
R"plot(1:10, 1:10)"
# throws a method error when running headless !
@test_throws(MethodError, RCall.ijulia_displayplots())
RCall.ijulia_setdevice(MIME("image/svg+xml"))
R"plot(-1 * 1:10, -1 * 1:10)"
# throws a method error when running headless !
@test_throws(MethodError, RCall.ijulia_displayplots())
RCall.ijulia_cleanup()
