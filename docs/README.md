### Building Documentations

[Lapidary](https://github.com/MichaelHatherly/Lapidary.jl) is used to generate the documentations automatically.

```bash
# install mkdocs if necessary
pip install mkdocs
cd /path/to/RCall/docs
julia make.jl
mkdocs build --clean
mkdocs gh-deploy
```
