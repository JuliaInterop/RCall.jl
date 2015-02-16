# `RCall`: Embedding R in Julia

I have used [R](http://www.r-project.org) (and S before it) for a
couple of decades.  In the last few years I have done more development
in [Julia](http://julialang.org), a language for technical computing
that can provide remarkable performance via Just-In-Time (JIT)
compilation of functions, than in R but there are still facilities in
R that I would like to use in Julia.  The
[RCall](http://github.com/JuliaStats/RCall.jl) package is a way of
scratching that itch.

Let me cut to the chase and describe the remarkable aspect of the
RCall package.  It is a pure Julia package.  In other words, there is
no code in C or C++ or another such language necessary to implement
calling R from Julia.  For those who have done this kind of thing,
that is remarkable.

I also want to show that it is possible to exploit the advantages of both
languages.  Sometimes language comparisons are rancorous exchanges
devolving into an "us against them" mentality.  I would rather take
Rodney King's "can't we all just get along" approach.

## Background on the languages

R is a well-established language with a mature infrastructure.  Julia
is still in an active, early development phase; the current release
is the 0.3.5 version.  The 0.4.0 release will include incompatible
changes;  that's what happens during the early development of a
language.  Software development can sometimes be, as stated in an old
blues song, a case of "keep doing it wrong until you do it right".

Sometimes it makes sense to reinvent the wheel
when transitioning from one language to another.  For example, I have
rewritten much of mixed-models fitting methods in the
[lme4](https://github.com/lme4/lme4) package for R as the
[MixedModels](https://github.com/dmbates/Mixedmodels.jl) package for
Julia.

Other times it doesn't make sense to immediately try to duplicate all the
facilities of one language in another.  R has a sophisticated system
for storing data sets compactly and in such a way as to preserve
metadata.  Many, perhaps most, of the several thousand packages for R
provide data sets for illustration of the techniques implemented in
the package.  Designing, writing and testing a system for saving and
retrieving data from Julia (as is done in the
[HDF5](https://github.com/timholy/HDF5/) package) does not by itself
provide access to all these data sets.

However, R does have a well-documented C API (Applications Programming
Interface) for creating an embedded instance of its interpretter.  And
Julia has very powerful facilities for accessing a C API.  It's an
natural match, although it did take me a couple of years to realize
that.

This is not a novel idea by any means.  Julia already has
[PyCall](https://github.com/stevengj/PyCall.jl) and
[JavaCall](https://github.com/aviks/JavaCall.jl) packages that provide
access to Python and Java.  These packages are used extensively and
are much more sophisticated than RCall, at present.

The purpose of this post is to describe some of the internals of R
that allow for starting and communicating with an embedded R
interpreter and to show how this can be accomplished in Julia.

## The C API for R

R's C API is documented in the
[Writing R Extensions](http://cran.rstudio.com/doc/manuals/r-release/R-exts.html)
manual.  The first thing to learn is that essentially all objects in R
are instances of a union of C structs.  The union is called an `SEXPREC` (symbolic
expression).  The `SEXP` type is a pointer to an `SEXPREC`.  The
majority of the C functions in the R API pass one or more `SEXP`
arguments and return an `SEXP`.

The various types of `SEXPREC`s are distinguished by a code in the
initial 32-bit word of the structure.  These 5-bit codes are given
symbolic names such as NILSXP, SYMSXP, ... in the R header files and
these names are reproduced in the `src/R_h.jl` file of the `RCall`
package.

An `SEXP` is represented in `RCall` as a templated type, also called
`SEXP`, which contains only a void pointer.

```julia
type SEXP{N}                # N is the R SEXPREC type (see R_h.jl)
    p::Ptr{Void}
end
                            # determine the R SEXPREC type from the Ptr{Void}
sexp(p::Ptr{Void}) = SEXP{unsafe_load(convert(Ptr{Cint},p)) & 0x1f}(p)
```

The purpose of the templated type is to allow dispatch on the kind of
`SEXP`.  All Julia functions are generic functions that use multiple
dispatch (i.e. the choice of method is not based solely on the first
argument to the function; it is based on the entire argument
signature).  If that last sentence is unintelligible to you just
accept that it is very useful to know the type of an `SEXP` without
needing to dig that information out of the structure each time you use
it.

The expression
```julia
unsafe_load(convert(Ptr{Cint},p) & 0x1f)
```
in the definition of this `sexp` method accesses the first 32-bit
word in the memory pointed to by `p` as an `int`
type in C and uses a mask to return the value of the trailing 5 bits.


### Vector structures in R

Several of the `SEXPREC` types in R represent a data vector.  These
include `LGLSXP` (the `logical` type), `INTSXP` (the `integer` type),
`REALSXP` (the `numeric` or `double` type) and so on.  The length of
the vector is in the C struct at a fixed offset from the `SEXP`
itself, as are the contents of the vector, for what are called "bits
types" in Julia.  As part of the initialization of the `RCall` package
the offset of the length from the beginning of the struct to the
32-bit integer which is the length is saved as `loffset`.  Similarly,
the offset from the beginning of the struct to the vector contents is
evaluated and saved as `voffset`.

When deciding how to access in Julia the contents of an R vector a
basic issue is whether to copy the contents or to share the contents.
Initially I chose to share the contents but doing so gets very tricky
because R and Julia each have their own memory allocation and garbage
collection.  Eventually I decided it was much easier to copy the
contents.

The metaprogramming tools in Julia allow for defining methods for the
`length` function in the `Base` module and for a new generic `copyvec`
in a loop.
```julia
for N in [LGLSXP,INTSXP,REALSXP,CPLXSXP,STRSXP,VECSXP,EXPRSXP]
    @eval begin
        Base.length(s::SEXP{$N}) = unsafe_load(convert(Ptr{Cint},s.p+loffset),1)
    end
end
for (N,typ) in ((INTSXP,:Int32),(REALSXP,:Float64),(CPLXSXP,:Complex128))
    @eval begin
        copyvec(s::SEXP{$N}) = copy(pointer_to_array(convert(Ptr{$typ},s.p+voffset),length(s)))
    end
end
```

Some of the R types that behave as vectors, such as the `character`
type (`STRSXP`) and the `list` type (confusing called an `VECSXP`), do
have a length but are not bits types in that the vector contents are
pointers to other structures.

This definition of the length method does not handle "long" vectors from
R which store the length as a 64-bit integer.  The actual version in
the package does.

In R a `logical` or Boolean vector (`LGLSXP`) is a vector of 32-bit
integers.  In a Julia `Bool` vector or array the individual values are
bytes, which is another reason that copying the R values into Julia
structs is more convenient that trying to share the contents.

### Missing data in vectors.

Missing data values are represented in R with a sentinel.  For double
precision values the sentinel is one of the NaN values.  For integer
and logical values the sentinel is the largest negative 32-bit
integer.  These values are assigned to `R_NaReal` and `R_NaInt` on
initialization of the `RCall` package.  Methods for an `isNA` generic
are defined first for scalars then for an array.

```julia
isNA(x::Cdouble) = x == R_NaReal
isNA(x::Cint) = x == R_NaInt
isNA(a::Array) = reshape(bitpack([isNA(aa) for aa in a]),size(a))
```

The `isNA` method for arrays uses methods for the `size` generic from
the `Base` module.  These methods are a bit more complicated than the
`length` methods because the `dim` function in R returns a null value
unless its argument is a multidimensional array, whereas the Julia
`size` method should return a dimension "tuple" for both vectors and
multidimensional arrays.  If you want to know the gory details, the
methods are defined in `src/sexp.jl`.

Currently the Julia packages `DataArrays` and `DataFrames` provide the
representation of arrays whose values can be missing data and for
objects like the R `data.frame` class.  The `DataArrays` package does
not use sentinels; instead it pairs the array of data values with a
bit array indicating for each element whether or not it is missing.
This is why the vector generated by the comprehension
`[isNA(aa) for aa in a]` is packed into a bit array then reshaped
according to the dimensions of the original array, `a`.

A raw Julia vector is converted to a `DataArray` by
```julia
for N in [INTSXP,REALSXP,CPLXSXP,STRSXP]
    @eval begin
        function DataArrays.DataArray(s::SEXP{$N})
            rv = reshape(copyvec(s),size(s))
            DataArray(rv,isNA(rv)))
        end
        dataset(s::SEXP{$N}) = DataArray(s)
    end
end
```

The `dataset` method for an integer vector defined here is immediately
overwritten with a more complicated method that checks whether the
integer array is a factor.
Factors are converted to the `PooledDataArray` type
```julia
function dataset(s::SEXP{INTSXP})
    isFactor(s) || return DataArray(s)
    ## refs array uses a zero index where R has a missing value, R_NaInt
    refs = DataArrays.RefArray(map!(x -> x == R_NaInt ? zero(Int32) : x,copyvec(s)))
    compact(PooledDataArray(refs,R.levels(s)))
end
```

## Element extraction and iterators

The `dataset` methods are for convenience.  Most data sets in R
packages are stored as `data.frame`s but some are simply data
vectors.  These methods, combined with a `dataset` method for R `list` (`VECSXP`)
objects, provide for general conversion of R data objects.

The `dataset` method for `SEXP{VECSXP}` uses an iterator, which we
first define

```julia
for (N,elt) in ((STRSXP,:STRING_ELT),(VECSXP,:VECTOR_ELT),(EXPRSXP,:VECTOR_ELT))
    @eval begin
        function Base.getindex(s::SEXP{$N},I::Number)  # extract a single element
            0 < I ≤ length(s) || throw(BoundsError())
            sexp(ccall(($(string(elt)),libR),Ptr{Void},(Ptr{Void},Cint),s,I-1))
        end
        Base.start(s::SEXP{$N}) = 0  # start,next,done and eltype provide an iterator
        Base.next(s::SEXP{$N},state) = (state += 1;(s[state],state))
        Base.done(s::SEXP{$N},state) = state ≥ length(s)
        Base.eltype(s::SEXP{$N}) = SEXP
    end
end
Base.eltype(s::SEXP{STRSXP}) = SEXP{CHARSXP} # be more specific for STRSXP

Base.names(s::SEXP) = copyvec(sexp(ccall((:Rf_getAttrib,libR),Ptr{Void},
                                         (Ptr{Void},Ptr{Void}),s,namesSymbol)))
function dataset(s::SEXP{VECSXP})
    val = [dataset(v) for v in s]
    isFrame(s) ? DataFrame(val,Symbol[symbol(nm) for nm in names(s)]) : val
end
```
allow for data frames and vectors to be converted to the corresponding
Julia objects.

## Bootstrapping the system

To this point we have described how the `RCall` package handles
various types of `SEXP` objects but not how these objects are created
in the first place.

First we need to open a dynamic library that contains the compiled C
code for R.  The standard method for resolving external dependencies
for a Julia package is to create a file `deps/build.jl` for the
package.  If this file exists, it is executed during the installation
of a Julia package or manually via a call to, e.g.
```julia
Pkg.build("RCall")
```

Typically the `deps/build.jl` file checks for a dynamic library,
building or installing it if needed, and writes a file `deps/deps.jl`
that is executed when the package is attached.

In the case of the `RCall` package `deps/build.jl` checks for
environment variables required by R and for the location of the
dynamic library.  These values are written to `deps/deps.jl`.  If
needed, these values are extracted by running a short R script using
`Rscript`.

When the `RCall` package is attached it runs an initialization
function that starts an embedded R instance and defines several global
constants.
```julia
function __init__()
    argv = ["Rembed","--silent"]
    i = ccall((:Rf_initEmbeddedR,libR),Cint,(Cint,Ptr{Ptr{Uint8}}),length(argv),argv)
    i > 0 || error("initEmbeddedR failed.  Try running Pkg.build(\"RCall\").")
    global const R_NaInt =  unsafe_load(cglobal((:R_NaInt,libR),Cint),1)
    global const R_NaReal = unsafe_load(cglobal((:R_NaReal,libR),Cdouble),1)
    global const R_NaString = sexp(unsafe_load(cglobal((:R_NaString,libR),Ptr{Void}),1))
    global const classSymbol = sexp(unsafe_load(cglobal((:R_ClassSymbol,libR),Ptr{Void}),1))
    global const emptyEnv = sexp(unsafe_load(cglobal((:R_EmptyEnv,libR),Ptr{Void}),1))
    global const dimSymbol = sexp(unsafe_load(cglobal((:R_DimSymbol,libR),Ptr{Void}),1))
    global const globalEnv = sexp(unsafe_load(cglobal((:R_GlobalEnv,libR),Ptr{Void}),1))
    global const levelsSymbol = sexp(unsafe_load(cglobal((:R_LevelsSymbol,libR),Ptr{Void}),1))
    global const namesSymbol = sexp(unsafe_load(cglobal((:R_NamesSymbol,libR),Ptr{Void}),1))
    global const nilValue = sexp(unsafe_load(cglobal((:R_NilValue,libR),Ptr{Void}),1))
    rone = sexp(1.)
    ## offsets (in bytes) from the Ptr{Void} to an R object and its vector contents
    global const voffset = int(ccall((:REAL,libR),Ptr{Void},(Ptr{Void},),rone) - rone.p)
    ## offsets (in bytes) from the Ptr{Void} to an R object and its length
    global const loffset = voffset - 2*sizeof(Cint)
end
```

Of these constants, the most important is `globalEnv`, because R
expressions must be evaluated in an environment and `globalEnv` points
to the global evaluation environment.  All the other constants could
be derived by evaluating expressions but `globalEnv` is needed before
you can evaluate anything else.  The last two expressions provide the
values of `voffset` and `loffset`.

Methods for the Julia `reval` function end up calling `R_tryEval`
in the C API for R.  Methods for the Julia `rparse` function
end up calling `R_ParseVector` in the C API.  For convenience several
predicate functions are defined in the R API.  These are wrapped as
Julia functions
```julia
for sym in (:isArray,:isComplex,:isEnvironment,:isExpression,:isFactor,
            :isFrame,:isFree,:isFunction,:isInteger,:isLanguage,:isList,
            :isLogical,:isSymbol,:isMatrix,:isNewList,:isNull,:isNumeric,
            :isNumber,:isObject,:isOrdered,:isPairList,:isPrimitive,
            :isReal,:isS4,:isString,:isTs,:isUnordered,:isUnsorted,
            :isUserBinop,:isValidString,:isValidStringF,:isVector,
            :isVectorAtomic,:isVectorizable,:isVectorList)
    @eval $sym(s::SEXP) = ccall(($(string("Rf_",sym)),libR),Bool,(Ptr{Void},),s)
end
```
although not all these functions are exported by `RCall` and many are
unnecessary for the templated `SEXP` type.

## Copying Julia bitstype objects and arrays to R objects

Because all Julia functions are generic, we can define methods for
`sexp` that take a Julia object, create a corresponding R object and
copy the contents from Julia to R.  The C API for R has several
functions to create "scalars" (which are actually vectors of length 1
in R), vectors, matrices, 3-dimensional arrays and more general
arrays.  All of these methods are defined using metaprogramming
```julia
for (typ,rnm,tag,rtyp) in ((:Bool,:Logical,LGLSXP,:Int32),
                           (:Complex,:Complex,CPLXSXP,:Complex128),
                           (:Integer,:Integer,INTSXP,:Int32),
                           (:Real,:Real,REALSXP,:Float64))
    @eval begin
        function sexp(v::$typ)
            preserve(sexp(ccall(($(string("Rf_Scalar",rnm)),libR),Ptr{Void},($rtyp,),v)))
        end
        function sexp{T<:$typ}(v::Vector{T})
            l = length(v)
            vv = sexp(ccall((:Rf_allocVector,libR),Ptr{Void},(Cint,Cptrdiff_t),$tag,l))
            copy!(pointer_to_array(convert(Ptr{$rtyp},vv.p+voffset),l),v)
            preserve(vv)
        end
        function sexp{T<:$typ}(m::Matrix{T})
            p,q = size(m)
            vv = sexp(ccall((:Rf_allocMatrix,libR),Ptr{Void},(Cint,Cint,Cint),$tag,p,q))
            copy!(pointer_to_array(convert(Ptr{$rtyp},vv.p+voffset),p*q),m)
            preserve(vv)
        end
        function sexp{T<:$typ}(a::Array{T,3})
            p,q,r = size(a)
            vv = sexp(ccall((:Rf_alloc3DArray,libR),Ptr{Void},(Cint,Cint,Cint,Cint),$tag,p,q,r))
            copy!(pointer_to_array(convert(Ptr{$rtyp},vv.p+voffset),length(a)),a)
            preserve(vv)
        end
        function sexp{T<:$typ}(a::Array{T})
            rdims = sexp([size(a)...])
            vv = sexp(ccall((:Rf_allocArray,libR),Ptr{Void},(Cint,Ptr{Void}),$tag,rdims))
            copy!(pointer_to_array(convert(Ptr{$rtyp},vv.p+voffset),length(a)),a)
            preserve(vv)
        end
    end
end
```

Separate methods are needed for Julia symbols, character strings and
vectors of strings.
```julia
sexp(s::Symbol) = sexp(ccall((:Rf_install,libR),Ptr{Void},(Ptr{Uint8},),string(s)))
sexp(st::Union(ASCIIString,UTF8String)) = sexp(ccall((:Rf_mkString,libR),Ptr{Void},(Ptr{Uint8},),st))
function sexp{T<:Union(ASCIIString,UTF8String)}(v::Vector{T})
    l = length(v)
    vv = sexp(ccall((:Rf_allocVector,libR),Ptr{Void},(Cint,Cptrdiff_t),STRSXP,l))
    for i in 1:l
        ccall((:SET_STRING_ELT,libR),Void,(Ptr{Void},Cint,Ptr{Void}),
              vv,i-1,ccall((:Rf_mkChar,libR),Ptr{Void},(Ptr{Uint8},),v[i]))
    end
    preserve(vv)
end
```

## Leftovers

A developer's choice of programming language creates some inertia.
All of us have a substantial investment of time to learn a language
and it is usually faster to use a language we know well on a problem
than to learn another language that may be better suited to the
problem.

For statisticians the language of choice is usually
[R](http://www.r-project.org).  I should point out that this wasn't
always the case.  I have been involved with the R community
more-or-less from its inception and with the development of the S
language before that.  Initially S was dismissed as "not suitable for
__real__ data analysis" (in comparison with batch-oriented languages
like SAS, SPSS, BMDP) and later R was dismissed as the "student
edition" or the "freeware version" of S-PLUS.

For the last couple of years I have been learning and developing in
[Julia](http://julialang.org) which, for me, is another step in
language evolution.
Julia is a language for technical computing that leverages recent
developments in compiler technology, especially
[LLVM](http://llvm.org), the Low-Level Virtual Machine project, to
provide "Just-In-Time" (JIT) compilation.  Like R and
[Matlab](http://www.mathworks.com/matlab)/[Octave](http://octave.org),
Julia is a functional programming language, in the sense that it is
based on the evaluations of functions.  All functions in Julia are
generic functions using multiple dispatch.
