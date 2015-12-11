all: check mkdocs

check:
	julia --check-bounds=yes -e 'Pkg.build("RCall"); Pkg.test("RCall")'

mkdocs:
	julia docs/build.jl;\
	mkdocs build --clean

gh-deploy:
	julia docs/build.jl;\
	mkdocs gh-deploy --clean
