### Building Documentations

[Documenter](https://github.com/MichaelHatherly/Documenter.jl) is used to generate
the documentations automatically. Lastest documentations of the master branch
and documentataions of tags are generated and deployed automatically to gh-
pages.

To view the docs locally, you first need to install Documenter.jl:

    julia -e 'Pkg.clone("https://github.com/MichaelHatherly/Documenter.jl")'

then run the following from within this directory:

    julia make.jl
    mkdocs serve