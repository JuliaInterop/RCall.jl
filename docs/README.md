### Building Documentations

[Lexicon](https://github.com/MichaelHatherly/Lexicon.jl) is used to extract the function's docstrings and generate the markdowns. See the [build](https://github.com/JuliaStats/RCall.jl/blob/master/docs/build.jl) script under the docs directory. Running it will generate the markdown files. For example,
```bash
julia docs/build.jl
```

To push the files to readthedocs: right now, we have to trigger the build manually in readthedocs website. When this thing gets more mature, we should turn on the [webhook](http://read-the-docs.readthedocs.org/en/latest/webhooks.html).

*Update* 

As readthedocs and mkdocs do not play [well](https://github.com/rtfd/readthedocs.org/issues/1487), search function is broken. For the moment, the docs are hosted on [github.io](http://juliastats.github.io/RCall.jl/).

To deploy the documents to gh-page, we need `mkdocs`,

```bash
# install mkdocs if necessary
pip install mkdocs
cd /path/to/RCall
julia docs/build.jl
mkdocs build --clean
mkdocs gh-deploy
```
