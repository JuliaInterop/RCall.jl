# RCall


## Methods [Exported]

---

<a id="method__anyna.1" class="lexicon_definition"></a>
#### anyNA{S<:RCall.VectorSxp}(s::Ptr{S<:RCall.VectorSxp}) [¶](#method__anyna.1)
Check if there are any NA values in the vector.


*source:*
[RCall/src/methods.jl:309](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L309)

---

<a id="method__getnames.1" class="lexicon_definition"></a>
#### getNames{S<:RCall.VectorSxp}(s::Ptr{S<:RCall.VectorSxp}) [¶](#method__getnames.1)
Returns the names of an R vector.


*source:*
[RCall/src/methods.jl:234](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L234)

---

<a id="method__isna.1" class="lexicon_definition"></a>
#### isNA(x::Complex{Float64}) [¶](#method__isna.1)
Check if values correspond to R's sentinel NA values.


*source:*
[RCall/src/methods.jl:288](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L288)

---

<a id="method__rcall.1" class="lexicon_definition"></a>
#### rcall(f,  args...) [¶](#method__rcall.1)
Evaluate a function in the global environment. The first argument corresponds
to the function to be called. It can be either a FunctionSxp type, a SymSxp or
a Symbol.

*source:*
[RCall/src/functions.jl:25](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/functions.jl#L25)

---

<a id="method__rcopy.1" class="lexicon_definition"></a>
#### rcopy(s::Ptr{RCall.SymSxp}) [¶](#method__rcopy.1)
`rcopy` copies the contents of an R object into a corresponding canonical Julia type.


*source:*
[RCall/src/convert-default.jl:6](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/convert-default.jl#L6)

---

<a id="method__rcopy.2" class="lexicon_definition"></a>
#### rcopy(str::AbstractString) [¶](#method__rcopy.2)
Evaluate and convert the result of a string as an R expression.


*source:*
[RCall/src/iface.jl:40](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/iface.jl#L40)

---

<a id="method__rcopy.3" class="lexicon_definition"></a>
#### rcopy{S<:RCall.Sxp}(::Type{Any},  x::Ptr{S<:RCall.Sxp}) [¶](#method__rcopy.3)
`rcopy(T,p)` converts a pointer `p` to a Sxp object to a native Julia object of type T.

`rcopy(p)` performs a default conversion.


*source:*
[RCall/src/convert-base.jl:9](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/convert-base.jl#L9)

---

<a id="method__reval.1" class="lexicon_definition"></a>
#### reval(s) [¶](#method__reval.1)
Evaluate an R symbol or language object (i.e. a function call) in an R
try/catch block, returning an RObject.


*source:*
[RCall/src/iface.jl:32](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/iface.jl#L32)

---

<a id="method__reval.2" class="lexicon_definition"></a>
#### reval(s,  env) [¶](#method__reval.2)
Evaluate an R symbol or language object (i.e. a function call) in an R
try/catch block, returning an RObject.


*source:*
[RCall/src/iface.jl:32](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/iface.jl#L32)

---

<a id="method__rparse.1" class="lexicon_definition"></a>
#### rparse(st::AbstractString) [¶](#method__rparse.1)
Parse a string as an R expression, returning an RObject.

*source:*
[RCall/src/iface.jl:63](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/iface.jl#L63)

---

<a id="method__rprint.1" class="lexicon_definition"></a>
#### rprint(io::IO,  str::ByteString) [¶](#method__rprint.1)
Parse, evaluate and print the result of a string as an R expression.


*source:*
[RCall/src/iface.jl:102](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/iface.jl#L102)

---

<a id="method__rprint.2" class="lexicon_definition"></a>
#### rprint{S<:RCall.Sxp}(io::IO,  s::Ptr{S<:RCall.Sxp}) [¶](#method__rprint.2)
Print the value of an Sxp using R's printing mechanism

*source:*
[RCall/src/iface.jl:67](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/iface.jl#L67)

---

<a id="method__setnames.1" class="lexicon_definition"></a>
#### setNames!{S<:RCall.VectorSxp}(s::Ptr{S<:RCall.VectorSxp},  n::Ptr{RCall.StrSxp}) [¶](#method__setnames.1)
Set the names of an R vector.


*source:*
[RCall/src/methods.jl:240](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L240)

## Types [Exported]

---

<a id="type__charsxp.1" class="lexicon_definition"></a>
#### RCall.CharSxp [¶](#type__charsxp.1)
R character string

*source:*
[RCall/src/types.jl:91](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L91)

---

<a id="type__clossxp.1" class="lexicon_definition"></a>
#### RCall.ClosSxp [¶](#type__clossxp.1)
R function closure

*source:*
[RCall/src/types.jl:43](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L43)

---

<a id="type__cplxsxp.1" class="lexicon_definition"></a>
#### RCall.CplxSxp [¶](#type__cplxsxp.1)
R complex vector

*source:*
[RCall/src/types.jl:132](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L132)

---

<a id="type__intsxp.1" class="lexicon_definition"></a>
#### RCall.IntSxp [¶](#type__intsxp.1)
R integer vector

*source:*
[RCall/src/types.jl:116](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L116)

---

<a id="type__lglsxp.1" class="lexicon_definition"></a>
#### RCall.LglSxp [¶](#type__lglsxp.1)
R logical vector

*source:*
[RCall/src/types.jl:108](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L108)

---

<a id="type__nilsxp.1" class="lexicon_definition"></a>
#### RCall.NilSxp [¶](#type__nilsxp.1)
R NULL value

*source:*
[RCall/src/types.jl:28](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L28)

---

<a id="type__robject.1" class="lexicon_definition"></a>
#### RCall.RObject{S<:RCall.Sxp} [¶](#type__robject.1)
An `RObject` is a Julia wrapper for an R object (known as an "S-expression" or "SEXP"). It is stored as a pointer which is protected from the R garbage collector, until the `RObject` itself is finalized by Julia. The parameter is the type of the S-expression.

When called with a Julia object as an argument, a corresponding R object is constructed.

```julia_skip
julia> RObject(1)
RObject{IntSxp}
[1] 1

julia> RObject(1:3)
RObject{IntSxp}
[1] 1 2 3

julia> RObject(1.0:3.0)
RObject{RealSxp}
[1] 1 2 3
```



*source:*
[RCall/src/types.jl:257](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L257)

---

<a id="type__realsxp.1" class="lexicon_definition"></a>
#### RCall.RealSxp [¶](#type__realsxp.1)
R real vector

*source:*
[RCall/src/types.jl:124](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L124)

---

<a id="type__strsxp.1" class="lexicon_definition"></a>
#### RCall.StrSxp [¶](#type__strsxp.1)
R vector of character strings

*source:*
[RCall/src/types.jl:140](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L140)

---

<a id="type__sxp.1" class="lexicon_definition"></a>
#### RCall.Sxp [¶](#type__sxp.1)
R symbolic expression (`SxpPtr`): these are represented by a pointer to a
symbolic expression record (`Sxp`).


*source:*
[RCall/src/types.jl:5](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L5)

## Macros [Exported]

---

<a id="macro___rget.1" class="lexicon_definition"></a>
#### @rget(args...) [¶](#macro___rget.1)
Copies variables from R to Julia using the same name.


*source:*
[RCall/src/iface.jl:128](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/iface.jl#L128)

---

<a id="macro___rput.1" class="lexicon_definition"></a>
#### @rput(args...) [¶](#macro___rput.1)
Copies variables from Julia to R using the same name.


*source:*
[RCall/src/iface.jl:108](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/iface.jl#L108)

---

<a id="macro___var_str.1" class="lexicon_definition"></a>
#### @var_str(str) [¶](#macro___var_str.1)
Returns a variable named "str". Useful for passing keyword arguments containing dots.


*source:*
[RCall/src/functions.jl:35](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/functions.jl#L35)


## Methods [Internal]

---

<a id="method__nael.1" class="lexicon_definition"></a>
#### NAel(::Type{RCall.LglSxp}) [¶](#method__nael.1)
NA element for each type


*source:*
[RCall/src/methods.jl:277](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L277)

---

<a id="method__bound.1" class="lexicon_definition"></a>
#### bound{S<:RCall.Sxp}(s::Ptr{S<:RCall.Sxp}) [¶](#method__bound.1)
The R NAMED property, represented by 2 bits in the info field. This can take
values 0,1 or 2, corresponding to whether it is bound to 0,1 or 2 or more
symbols. See
http://cran.r-project.org/doc/manuals/r-patched/R-exts.html#Named-objects-and-copying


*source:*
[RCall/src/methods.jl:12](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L12)

---

<a id="method__calljuliaextptr.1" class="lexicon_definition"></a>
#### callJuliaExtPtr(p::Ptr{RCall.ListSxp}) [¶](#method__calljuliaextptr.1)
The function called by R .External for Julia callbacks.

It receives a `ListSxpPtr` containing
 - a pointer to the function itself (`ExtPtrSxpPtr`)
 - a pointer to the Julia function (`ExtPtrSxpPtr`)
 - any arguments (as `SxpPtr`)


*source:*
[RCall/src/callback.jl:32](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/callback.jl#L32)

---

<a id="method__dataptr.1" class="lexicon_definition"></a>
#### dataptr{S<:RCall.VectorSxp}(s::Ptr{S<:RCall.VectorSxp}) [¶](#method__dataptr.1)
Pointer to start of the data array in a SEXPREC. Corresponds to DATAPTR C macro.


*source:*
[RCall/src/methods.jl:47](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L47)

---

<a id="method__decrefextptr.1" class="lexicon_definition"></a>
#### decrefExtPtr(p::Ptr{RCall.ExtPtrSxp}) [¶](#method__decrefextptr.1)
Called by the R finalizer.


*source:*
[RCall/src/callback.jl:76](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/callback.jl#L76)

---

<a id="method__eltype.1" class="lexicon_definition"></a>
#### eltype(::Type{RCall.LglSxp}) [¶](#method__eltype.1)
Element types of R vectors.


*source:*
[RCall/src/types.jl:222](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L222)

---

<a id="method__findnamespace.1" class="lexicon_definition"></a>
#### findNamespace(str::ByteString) [¶](#method__findnamespace.1)
find namespace by name of the namespace

*source:*
[RCall/src/methods.jl:386](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L386)

---

<a id="method__getclass.1" class="lexicon_definition"></a>
#### getClass{S<:RCall.Sxp}(s::Ptr{S<:RCall.Sxp}) [¶](#method__getclass.1)
Returns the class of an R object.


*source:*
[RCall/src/methods.jl:246](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L246)

---

<a id="method__getindex.1" class="lexicon_definition"></a>
#### getindex(e::Ptr{RCall.EnvSxp},  s::Ptr{RCall.SymSxp}) [¶](#method__getindex.1)
extract the value of symbol s in the environment e

*source:*
[RCall/src/methods.jl:354](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L354)

---

<a id="method__getindex.2" class="lexicon_definition"></a>
#### getindex{S<:RCall.PairListSxp}(l::Ptr{S<:RCall.PairListSxp},  I::Integer) [¶](#method__getindex.2)
extract the i-th element of LangSxp l

*source:*
[RCall/src/methods.jl:177](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L177)

---

<a id="method__getindex.3" class="lexicon_definition"></a>
#### getindex{S<:RCall.VectorAtomicSxp}(s::Ptr{S<:RCall.VectorAtomicSxp},  I::Real) [¶](#method__getindex.3)
Indexing into `VectorSxp` types uses Julia indexing into the `vec` result,
except for `StrSxp` and the `VectorListSxp` types, which must apply `sexp`
to the `Ptr{Void}` obtained by indexing into the `vec` result.


*source:*
[RCall/src/methods.jl:80](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L80)

---

<a id="method__getindex.4" class="lexicon_definition"></a>
#### getindex{S<:RCall.VectorSxp}(s::Ptr{S<:RCall.VectorSxp},  label::AbstractString) [¶](#method__getindex.4)
String indexing finds the first element with the matching name


*source:*
[RCall/src/methods.jl:91](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L91)

---

<a id="method__ijulia_displayplots.1" class="lexicon_definition"></a>
#### ijulia_displayplots() [¶](#method__ijulia_displayplots.1)
Called after cell evaluation.
Closes graphics device and displays files in notebook.


*source:*
[RCall/src/IJulia.jl:53](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/IJulia.jl#L53)

---

<a id="method__ijulia_setdevice.1" class="lexicon_definition"></a>
#### ijulia_setdevice(m::MIME{mime}) [¶](#method__ijulia_setdevice.1)
Set options for R plotting with IJulia.

The first argument should be a MIME object: currently supported are
* `MIME("image/png")` [default]
* `MIME("image/svg+xml")`

The remaining arguments (keyword only) are passed to the appropriate R graphics
device: see the relevant R help for details.


*source:*
[RCall/src/IJulia.jl:17](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/IJulia.jl#L17)

---

<a id="method__isascii.1" class="lexicon_definition"></a>
#### isascii(s::RCall.CharSxp) [¶](#method__isascii.1)
Determines the encoding of the CharSxp. This is determined by the 'gp' part of the sxpinfo (this is the middle 16 bits).
 * 0x00_0002_00 (bit 1): set of bytes (no known encoding)
 * 0x00_0004_00 (bit 2): Latin-1
 * 0x00_0008_00 (bit 3): UTF-8
 * 0x00_0040_00 (bit 6): ASCII

We only support ASCII and UTF-8.


*source:*
[RCall/src/methods.jl:330](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L330)

---

<a id="method__length.1" class="lexicon_definition"></a>
#### length{S<:RCall.Sxp}(s::Ptr{S<:RCall.Sxp}) [¶](#method__length.1)
Sxp methods for `length` return the R length.

`Rf_xlength` handles Sxps that are not vector-like and R's
"long vectors", which have a negative value for the `length` member.


*source:*
[RCall/src/methods.jl:24](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L24)

---

<a id="method__makeexternalptr.1" class="lexicon_definition"></a>
#### makeExternalPtr(ptr::Ptr{Void}) [¶](#method__makeexternalptr.1)
Create an ExtPtrSxpPtr object

*source:*
[RCall/src/callback.jl:18](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/callback.jl#L18)

---

<a id="method__makeexternalptr.2" class="lexicon_definition"></a>
#### makeExternalPtr(ptr::Ptr{Void},  tag) [¶](#method__makeexternalptr.2)
Create an ExtPtrSxpPtr object

*source:*
[RCall/src/callback.jl:18](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/callback.jl#L18)

---

<a id="method__makeexternalptr.3" class="lexicon_definition"></a>
#### makeExternalPtr(ptr::Ptr{Void},  tag,  prot) [¶](#method__makeexternalptr.3)
Create an ExtPtrSxpPtr object

*source:*
[RCall/src/callback.jl:18](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/callback.jl#L18)

---

<a id="method__makenativesymbol.1" class="lexicon_definition"></a>
#### makeNativeSymbol(fptr::Ptr{Void}) [¶](#method__makenativesymbol.1)
Register a function pointer as an R NativeSymbol.

This is completely undocumented, so may break: we technically are supposed to
use R_registerRoutines, but this is _much_ easier for just 1 function.


*source:*
[RCall/src/callback.jl:7](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/callback.jl#L7)

---

<a id="method__newenvironment.1" class="lexicon_definition"></a>
#### newEnvironment(env::Ptr{RCall.EnvSxp}) [¶](#method__newenvironment.1)
create a new environment which extends env

*source:*
[RCall/src/methods.jl:380](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L380)

---

<a id="method__preserve.1" class="lexicon_definition"></a>
#### preserve{S<:RCall.Sxp}(p::Ptr{S<:RCall.Sxp}) [¶](#method__preserve.1)
Prevent garbage collection of an R object. Object can be released via `release`.

This is slower than `protect`, as it requires searching an internal list, but
more flexible.


*source:*
[RCall/src/types.jl:281](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L281)

---

<a id="method__protect.1" class="lexicon_definition"></a>
#### protect{S<:RCall.Sxp}(p::Ptr{S<:RCall.Sxp}) [¶](#method__protect.1)
Stack-based protection of garbage collection of R objects. Objects are
released via `unprotect`. Returns the same pointer, allowing inline use.

This is faster than `preserve`, but more restrictive. Really only useful
inside functions.


*source:*
[RCall/src/types.jl:296](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L296)

---

<a id="method__registerfinalizer.1" class="lexicon_definition"></a>
#### registerFinalizer(s::Ptr{RCall.ExtPtrSxp}) [¶](#method__registerfinalizer.1)
Register finalizer to be called by the R GC.


*source:*
[RCall/src/callback.jl:85](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/callback.jl#L85)

---

<a id="method__release.1" class="lexicon_definition"></a>
#### release{S<:RCall.Sxp}(p::Ptr{S<:RCall.Sxp}) [¶](#method__release.1)
Release object that has been gc protected by `preserve`.


*source:*
[RCall/src/types.jl:286](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L286)

---

<a id="method__reval_p.1" class="lexicon_definition"></a>
#### reval_p{S<:RCall.Sxp}(expr::Ptr{S<:RCall.Sxp},  env::Ptr{RCall.EnvSxp}) [¶](#method__reval_p.1)
Evaluate an R symbol or language object (i.e. a function call) in an R
try/catch block, returning a Sxp pointer.


*source:*
[RCall/src/iface.jl:5](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/iface.jl#L5)

---

<a id="method__rlang_p.1" class="lexicon_definition"></a>
#### rlang_p(f,  args...) [¶](#method__rlang_p.1)
Create a function call from a list of arguments

*source:*
[RCall/src/functions.jl:2](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/functions.jl#L2)

---

<a id="method__rparse_p.1" class="lexicon_definition"></a>
#### rparse_p(st::Ptr{RCall.StrSxp}) [¶](#method__rparse_p.1)
Parse a string as an R expression, returning a Sxp pointer.

*source:*
[RCall/src/iface.jl:47](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/iface.jl#L47)

---

<a id="method__setclass.1" class="lexicon_definition"></a>
#### setClass!{S<:RCall.Sxp}(s::Ptr{S<:RCall.Sxp},  c::Ptr{RCall.StrSxp}) [¶](#method__setclass.1)
Set the class of an R object.


*source:*
[RCall/src/methods.jl:253](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L253)

---

<a id="method__setindex.1" class="lexicon_definition"></a>
#### setindex!{S<:RCall.PairListSxp, T<:RCall.Sxp}(l::Ptr{S<:RCall.PairListSxp},  v::Ptr{T<:RCall.Sxp},  I::Integer) [¶](#method__setindex.1)
assign value v to the i-th element of LangSxp l

*source:*
[RCall/src/methods.jl:188](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L188)

---

<a id="method__setindex.2" class="lexicon_definition"></a>
#### setindex!{S<:RCall.Sxp}(e::Ptr{RCall.EnvSxp},  v::Ptr{S<:RCall.Sxp},  s::Ptr{RCall.SymSxp}) [¶](#method__setindex.2)
assign value v to symbol s in the environment e

*source:*
[RCall/src/methods.jl:364](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L364)

---

<a id="method__sexp.1" class="lexicon_definition"></a>
#### sexp(::Type{Int32},  x) [¶](#method__sexp.1)
`sexp(S,x)` converts a Julia object `x` to a pointer to a Sxp object of type `S`.

`sexp(x)` performs a default conversion.


*source:*
[RCall/src/convert-base.jl:29](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/convert-base.jl#L29)

---

<a id="method__sexp.2" class="lexicon_definition"></a>
#### sexp(::Type{RCall.CharSxp},  st::ASCIIString) [¶](#method__sexp.2)
Create a `CharSxp` from a String.


*source:*
[RCall/src/convert-base.jl:63](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/convert-base.jl#L63)

---

<a id="method__sexp.3" class="lexicon_definition"></a>
#### sexp(::Type{RCall.ClosSxp},  f) [¶](#method__sexp.3)
Wrap a callable Julia object `f` an a R `ClosSxpPtr`.

Constructs the following R code

    function(...) .External(rJuliaCallback, fExPtr, ...)



*source:*
[RCall/src/callback.jl:118](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/callback.jl#L118)

---

<a id="method__sexp.4" class="lexicon_definition"></a>
#### sexp(::Type{RCall.ExtPtrSxp},  j) [¶](#method__sexp.4)
Wrap a Julia object an a R `ExtPtrSxpPtr`.

We store the pointer and the object in a const Dict to prevent it being
removed by the Julia GC.


*source:*
[RCall/src/callback.jl:102](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/callback.jl#L102)

---

<a id="method__sexp.5" class="lexicon_definition"></a>
#### sexp(::Type{RCall.StrSxp},  s::Ptr{RCall.CharSxp}) [¶](#method__sexp.5)
Create a `StrSxp` from an `AbstractString`

*source:*
[RCall/src/convert-base.jl:77](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/convert-base.jl#L77)

---

<a id="method__sexp.6" class="lexicon_definition"></a>
#### sexp(::Type{RCall.SymSxp},  s::AbstractString) [¶](#method__sexp.6)
Create a `SymSxp` from a `Symbol`

*source:*
[RCall/src/convert-base.jl:46](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/convert-base.jl#L46)

---

<a id="method__sexp.7" class="lexicon_definition"></a>
#### sexp(p::Ptr{RCall.SxpHead}) [¶](#method__sexp.7)
Convert a `UnknownSxpPtr` to an approptiate `SxpPtr`.


*source:*
[RCall/src/types.jl:330](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L330)

---

<a id="method__sexp.8" class="lexicon_definition"></a>
#### sexp(s::Symbol) [¶](#method__sexp.8)
Generic function for constructing Sxps from Julia objects.

*source:*
[RCall/src/convert-base.jl:50](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/convert-base.jl#L50)

---

<a id="method__sexp_arglist_dots.1" class="lexicon_definition"></a>
#### sexp_arglist_dots(args...) [¶](#method__sexp_arglist_dots.1)
Create an argument list for an R function call, with a varargs "dots" at the end.


*source:*
[RCall/src/callback.jl:133](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/callback.jl#L133)

---

<a id="method__sexpnum.1" class="lexicon_definition"></a>
#### sexpnum(h::RCall.SxpHead) [¶](#method__sexpnum.1)
The SEXPTYPE number of a `Sxp`

Determined from the trailing 5 bits of the first 32-bit word. Is
a 0-based index into the `info` field of a `SxpHead`.


*source:*
[RCall/src/types.jl:309](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L309)

---

<a id="method__unprotect.1" class="lexicon_definition"></a>
#### unprotect(n::Integer) [¶](#method__unprotect.1)
Release last `n` objects gc-protected by `protect`.


*source:*
[RCall/src/types.jl:301](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L301)

---

<a id="method__unsafe_array.1" class="lexicon_definition"></a>
#### unsafe_array{S<:RCall.VectorSxp}(s::Ptr{S<:RCall.VectorSxp}) [¶](#method__unsafe_array.1)
The same as `unsafe_vec`, except returns an appropriately sized array.


*source:*
[RCall/src/methods.jl:70](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L70)

---

<a id="method__unsafe_vec.1" class="lexicon_definition"></a>
#### unsafe_vec{S<:RCall.VectorSxp}(s::Ptr{S<:RCall.VectorSxp}) [¶](#method__unsafe_vec.1)
Represent the contents of a VectorSxp type as a `Vector`.

This does __not__ copy the contents.  If the argument is not named (in R) or
otherwise protected from R's garbage collection (e.g. by keeping the
containing RObject in scope) the contents of this vector can be modified or
could cause a memory error when accessed.

The contents are as stored in R.  Missing values (NA's) are represented
in R by sentinels.  Missing data values in RealSxp and CplxSxp show
up as `NaN` and `NaN + NaNim`, respectively.  Missing data in IntSxp show up
as `-2147483648`, the minimum 32-bit integer value.  Internally a `LglSxp` is
represented as `Vector{Int32}`.  The convention is that `0` is `false`,
`-2147483648` is `NA` and all other values represent `true`.


*source:*
[RCall/src/methods.jl:64](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/methods.jl#L64)

## Types [Internal]

---

<a id="type__anysxp.1" class="lexicon_definition"></a>
#### RCall.AnySxp [¶](#type__anysxp.1)
R "any" object

*source:*
[RCall/src/types.jl:154](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L154)

---

<a id="type__bcodesxp.1" class="lexicon_definition"></a>
#### RCall.BcodeSxp [¶](#type__bcodesxp.1)
R byte code

*source:*
[RCall/src/types.jl:176](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L176)

---

<a id="type__builtinsxp.1" class="lexicon_definition"></a>
#### RCall.BuiltinSxp [¶](#type__builtinsxp.1)
R built-in function

*source:*
[RCall/src/types.jl:85](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L85)

---

<a id="type__dotsxp.1" class="lexicon_definition"></a>
#### RCall.DotSxp [¶](#type__dotsxp.1)
R dot-dot-dot object

*source:*
[RCall/src/types.jl:148](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L148)

---

<a id="type__envsxp.1" class="lexicon_definition"></a>
#### RCall.EnvSxp [¶](#type__envsxp.1)
R environment

*source:*
[RCall/src/types.jl:52](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L52)

---

<a id="type__exprsxp.1" class="lexicon_definition"></a>
#### RCall.ExprSxp [¶](#type__exprsxp.1)
R expression vector

*source:*
[RCall/src/types.jl:168](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L168)

---

<a id="type__extptrsxp.1" class="lexicon_definition"></a>
#### RCall.ExtPtrSxp [¶](#type__extptrsxp.1)
R external pointer

*source:*
[RCall/src/types.jl:182](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L182)

---

<a id="type__langsxp.1" class="lexicon_definition"></a>
#### RCall.LangSxp [¶](#type__langsxp.1)
R function call

*source:*
[RCall/src/types.jl:70](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L70)

---

<a id="type__listsxp.1" class="lexicon_definition"></a>
#### RCall.ListSxp [¶](#type__listsxp.1)
R pairs (cons) list cell

*source:*
[RCall/src/types.jl:34](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L34)

---

<a id="type__promsxp.1" class="lexicon_definition"></a>
#### RCall.PromSxp [¶](#type__promsxp.1)
R promise

*source:*
[RCall/src/types.jl:61](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L61)

---

<a id="type__rawsxp.1" class="lexicon_definition"></a>
#### RCall.RawSxp [¶](#type__rawsxp.1)
R byte vector

*source:*
[RCall/src/types.jl:197](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L197)

---

<a id="type__s4sxp.1" class="lexicon_definition"></a>
#### RCall.S4Sxp [¶](#type__s4sxp.1)
R S4 object

*source:*
[RCall/src/types.jl:205](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L205)

---

<a id="type__specialsxp.1" class="lexicon_definition"></a>
#### RCall.SpecialSxp [¶](#type__specialsxp.1)
R special function

*source:*
[RCall/src/types.jl:79](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L79)

---

<a id="type__sxphead.1" class="lexicon_definition"></a>
#### RCall.SxpHead [¶](#type__sxphead.1)
R Sxp header: a pointer to this is used for unknown types.

*source:*
[RCall/src/types.jl:11](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L11)

---

<a id="type__symsxp.1" class="lexicon_definition"></a>
#### RCall.SymSxp [¶](#type__symsxp.1)
R symbol

*source:*
[RCall/src/types.jl:99](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L99)

---

<a id="type__vecsxp.1" class="lexicon_definition"></a>
#### RCall.VecSxp [¶](#type__vecsxp.1)
R list (i.e. Array{Any,1})

*source:*
[RCall/src/types.jl:160](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L160)

---

<a id="type__weakrefsxp.1" class="lexicon_definition"></a>
#### RCall.WeakRefSxp [¶](#type__weakrefsxp.1)
R weak reference

*source:*
[RCall/src/types.jl:191](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L191)

## Globals [Internal]

---

<a id="global__jtypextptrs.1" class="lexicon_definition"></a>
#### jtypExtPtrs [¶](#global__jtypextptrs.1)
Julia types (typically functions) which are wrapped in `ExtPtrSxpPtr` are
stored here to prevent garbage collection by Julia.


*source:*
[RCall/src/callback.jl:71](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/callback.jl#L71)

---

<a id="global__typs.1" class="lexicon_definition"></a>
#### typs [¶](#global__typs.1)
vector of R Sxp types

*source:*
[RCall/src/types.jl:313](https://github.com/JuliaStats/RCall.jl/tree/7bbf9e154ac1ead274767ec81d72682aded1414a/src/types.jl#L313)

