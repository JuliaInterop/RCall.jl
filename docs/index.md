# `RCall`

[R](http://www.r-project.org) has been round for a couple of decades.  In the
last few years, a new language for technical computing,
[Julia](http://julialang.org), has arrived and provides remarkable performance
via Just-In-Time (JIT) compilation of functions than in R, but there are still
a lot of well-developed packages in R that could use in Julia.  The
[RCall](http://github.com/JuliaStats/RCall.jl) package is a way of
establishing communication between to two.

It is a pure Julia package.  In other words, there is
no code in C or C++ or another such language necessary to implement
calling R from Julia. It is possible to exploit the advantages of both
languages.