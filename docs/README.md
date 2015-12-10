### Building Documentations

Finally, I have added the [readthedocs](http://rcalljl.readthedocs.org/en/latest/?badge=latest) support which generates documentation files semi-automatically.

[Lexicon](https://github.com/MichaelHatherly/Lexicon.jl) is used to extract the function's docstrings and generate the markdowns. See the [build](https://github.com/JuliaStats/RCall.jl/blob/master/docs/build.jl) script under the docs directory. Running it will generate the markdown files. For example,
```bash
julia docs/build.jl
```

To push the files to readthedocs: right now, we have to trigger the build manually in readthedocs website. When this thing gets more mature, we should turn on the [webhook](http://read-the-docs.readthedocs.org/en/latest/webhooks.html).