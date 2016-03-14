### Building Documentations

[Lapidary](https://github.com/MichaelHatherly/Lapidary.jl) is used to generate
the documentations automatically. Lastest documentations are generated and
deployed automatically to gh-pages by Lapidary. To manually publish specific
version of documentations, use the followings

```bash
# install mkdocs if necessary
pip install mkdocs
# checkout specific version
git checkout v0.3.2
cd docs
julia make.jl
mkdocs build --clean
git clone --branch=gh-pages https://github.com/JuliaStats/RCall.jl gh-pages
mv site gh-pages/v0.3.2
cd gh-pages
git add -A
git commit -m 'Documentations v0.3.2'
git push
cd ..
rm gh-pages
```
