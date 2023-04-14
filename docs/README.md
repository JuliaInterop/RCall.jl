### Building Documentations

[Documenter](https://github.com/JuliaDocs/Documenter.jl) is used to generate
the documentations automatically. Documentation on master as well as releases
are automatically deployed to the gh-pages branch.

To view the docs locally, you first need to install Documenter.jl:

    julia -e 'Pkg.add("Documenter")'

then run the following from within this directory:

    julia make.jl

HTML files are generated in the `build` directory.
