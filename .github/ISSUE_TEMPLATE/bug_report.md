---
name: Bug report
about: Report a suspected bug or incompatibility in RCall.jl
title: ''
labels: ''
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Please try to create as small a reproduction as possible.

 * How did you install RCall.jl and configure the R location?
 * Did you install any R packages or other packages? Using what method? 
 * Finally what code did you run?

Please include this information even if it relates to an earlier issue which has been closed.

**Expected and actual behavior**
Describe what happened versus what you expected to happen.

**Version information**
Please include the output of follow commands in the REPL:

```julia
using RCall
RCall.debuginfo()
```

In case you have trouble running the above, you can instead include the output of:
```julia
using RCall
reval("sessionInfo()")
versioninfo()
```

**Additional context**
Add any other context about the problem here.
