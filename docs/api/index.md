# API-INDEX


## MODULE: RCall

---

## Methods [Exported]

[anyNA{S<:RCall.VectorSxp}(s::Ptr{S<:RCall.VectorSxp})](RCall.md#method__anyna.1)  Check if there are any NA values in the vector.

[getNames{S<:RCall.VectorSxp}(s::Ptr{S<:RCall.VectorSxp})](RCall.md#method__getnames.1)  Returns the names of an R vector.

[isNA(x::Complex{Float64})](RCall.md#method__isna.1)  Check if values correspond to R's sentinel NA values.

[rcall(f,  args...)](RCall.md#method__rcall.1)  Evaluate a function in the global environment. The first argument corresponds

[rcopy(s::Ptr{RCall.SymSxp})](RCall.md#method__rcopy.1)  `rcopy` copies the contents of an R object into a corresponding canonical Julia type.

[rcopy(str::AbstractString)](RCall.md#method__rcopy.2)  Evaluate and convert the result of a string as an R expression.

[rcopy{S<:RCall.Sxp}(::Type{Any},  x::Ptr{S<:RCall.Sxp})](RCall.md#method__rcopy.3)  `rcopy(T,p)` converts a pointer `p` to a Sxp object to a native Julia object of type T.

[reval(s)](RCall.md#method__reval.1)  Evaluate an R symbol or language object (i.e. a function call) in an R

[reval(s,  env)](RCall.md#method__reval.2)  Evaluate an R symbol or language object (i.e. a function call) in an R

[rparse(st::AbstractString)](RCall.md#method__rparse.1)  Parse a string as an R expression, returning an RObject.

[rprint(io::IO,  str::ByteString)](RCall.md#method__rprint.1)  Parse, evaluate and print the result of a string as an R expression.

[rprint{S<:RCall.Sxp}(io::IO,  s::Ptr{S<:RCall.Sxp})](RCall.md#method__rprint.2)  Print the value of an Sxp using R's printing mechanism

[setNames!{S<:RCall.VectorSxp}(s::Ptr{S<:RCall.VectorSxp},  n::Ptr{RCall.StrSxp})](RCall.md#method__setnames.1)  Set the names of an R vector.

---

## Types [Exported]

[RCall.CharSxp](RCall.md#type__charsxp.1)  R character string

[RCall.ClosSxp](RCall.md#type__clossxp.1)  R function closure

[RCall.CplxSxp](RCall.md#type__cplxsxp.1)  R complex vector

[RCall.IntSxp](RCall.md#type__intsxp.1)  R integer vector

[RCall.LglSxp](RCall.md#type__lglsxp.1)  R logical vector

[RCall.NilSxp](RCall.md#type__nilsxp.1)  R NULL value

[RCall.RObject{S<:RCall.Sxp}](RCall.md#type__robject.1)  An `RObject` is a Julia wrapper for an R object (known as an "S-expression" or "SEXP"). It is stored as a pointer which is protected from the R garbage collector, until the `RObject` itself is finalized by Julia. The parameter is the type of the S-expression.

[RCall.RealSxp](RCall.md#type__realsxp.1)  R real vector

[RCall.StrSxp](RCall.md#type__strsxp.1)  R vector of character strings

[RCall.Sxp](RCall.md#type__sxp.1)  R symbolic expression (`SxpPtr`): these are represented by a pointer to a

---

## Macros [Exported]

[@rget(args...)](RCall.md#macro___rget.1)  Copies variables from R to Julia using the same name.

[@rput(args...)](RCall.md#macro___rput.1)  Copies variables from Julia to R using the same name.

[@var_str(str)](RCall.md#macro___var_str.1)  Returns a variable named "str". Useful for passing keyword arguments containing dots.

---

## Methods [Internal]

[NAel(::Type{RCall.LglSxp})](RCall.md#method__nael.1)  NA element for each type

[bound{S<:RCall.Sxp}(s::Ptr{S<:RCall.Sxp})](RCall.md#method__bound.1)  The R NAMED property, represented by 2 bits in the info field. This can take

[callJuliaExtPtr(p::Ptr{RCall.ListSxp})](RCall.md#method__calljuliaextptr.1)  The function called by R .External for Julia callbacks.

[dataptr{S<:RCall.VectorSxp}(s::Ptr{S<:RCall.VectorSxp})](RCall.md#method__dataptr.1)  Pointer to start of the data array in a SEXPREC. Corresponds to DATAPTR C macro.

[decrefExtPtr(p::Ptr{RCall.ExtPtrSxp})](RCall.md#method__decrefextptr.1)  Called by the R finalizer.

[eltype(::Type{RCall.LglSxp})](RCall.md#method__eltype.1)  Element types of R vectors.

[findNamespace(str::ByteString)](RCall.md#method__findnamespace.1)  find namespace by name of the namespace

[getClass{S<:RCall.Sxp}(s::Ptr{S<:RCall.Sxp})](RCall.md#method__getclass.1)  Returns the class of an R object.

[getindex(e::Ptr{RCall.EnvSxp},  s::Ptr{RCall.SymSxp})](RCall.md#method__getindex.1)  extract the value of symbol s in the environment e

[getindex{S<:RCall.PairListSxp}(l::Ptr{S<:RCall.PairListSxp},  I::Integer)](RCall.md#method__getindex.2)  extract the i-th element of LangSxp l

[getindex{S<:RCall.VectorAtomicSxp}(s::Ptr{S<:RCall.VectorAtomicSxp},  I::Real)](RCall.md#method__getindex.3)  Indexing into `VectorSxp` types uses Julia indexing into the `vec` result,

[getindex{S<:RCall.VectorSxp}(s::Ptr{S<:RCall.VectorSxp},  label::AbstractString)](RCall.md#method__getindex.4)  String indexing finds the first element with the matching name

[ijulia_displayplots()](RCall.md#method__ijulia_displayplots.1)  Called after cell evaluation.

[ijulia_setdevice(m::MIME{mime})](RCall.md#method__ijulia_setdevice.1)  Set options for R plotting with IJulia.

[isascii(s::RCall.CharSxp)](RCall.md#method__isascii.1)  Determines the encoding of the CharSxp. This is determined by the 'gp' part of the sxpinfo (this is the middle 16 bits).

[length{S<:RCall.Sxp}(s::Ptr{S<:RCall.Sxp})](RCall.md#method__length.1)  Sxp methods for `length` return the R length.

[makeExternalPtr(ptr::Ptr{Void})](RCall.md#method__makeexternalptr.1)  Create an ExtPtrSxpPtr object

[makeExternalPtr(ptr::Ptr{Void},  tag)](RCall.md#method__makeexternalptr.2)  Create an ExtPtrSxpPtr object

[makeExternalPtr(ptr::Ptr{Void},  tag,  prot)](RCall.md#method__makeexternalptr.3)  Create an ExtPtrSxpPtr object

[makeNativeSymbol(fptr::Ptr{Void})](RCall.md#method__makenativesymbol.1)  Register a function pointer as an R NativeSymbol.

[newEnvironment(env::Ptr{RCall.EnvSxp})](RCall.md#method__newenvironment.1)  create a new environment which extends env

[preserve{S<:RCall.Sxp}(p::Ptr{S<:RCall.Sxp})](RCall.md#method__preserve.1)  Prevent garbage collection of an R object. Object can be released via `release`.

[protect{S<:RCall.Sxp}(p::Ptr{S<:RCall.Sxp})](RCall.md#method__protect.1)  Stack-based protection of garbage collection of R objects. Objects are

[registerFinalizer(s::Ptr{RCall.ExtPtrSxp})](RCall.md#method__registerfinalizer.1)  Register finalizer to be called by the R GC.

[release{S<:RCall.Sxp}(p::Ptr{S<:RCall.Sxp})](RCall.md#method__release.1)  Release object that has been gc protected by `preserve`.

[reval_p{S<:RCall.Sxp}(expr::Ptr{S<:RCall.Sxp},  env::Ptr{RCall.EnvSxp})](RCall.md#method__reval_p.1)  Evaluate an R symbol or language object (i.e. a function call) in an R

[rlang_p(f,  args...)](RCall.md#method__rlang_p.1)  Create a function call from a list of arguments

[rparse_p(st::Ptr{RCall.StrSxp})](RCall.md#method__rparse_p.1)  Parse a string as an R expression, returning a Sxp pointer.

[setClass!{S<:RCall.Sxp}(s::Ptr{S<:RCall.Sxp},  c::Ptr{RCall.StrSxp})](RCall.md#method__setclass.1)  Set the class of an R object.

[setindex!{S<:RCall.PairListSxp, T<:RCall.Sxp}(l::Ptr{S<:RCall.PairListSxp},  v::Ptr{T<:RCall.Sxp},  I::Integer)](RCall.md#method__setindex.1)  assign value v to the i-th element of LangSxp l

[setindex!{S<:RCall.Sxp}(e::Ptr{RCall.EnvSxp},  v::Ptr{S<:RCall.Sxp},  s::Ptr{RCall.SymSxp})](RCall.md#method__setindex.2)  assign value v to symbol s in the environment e

[sexp(::Type{Int32},  x)](RCall.md#method__sexp.1)  `sexp(S,x)` converts a Julia object `x` to a pointer to a Sxp object of type `S`.

[sexp(::Type{RCall.CharSxp},  st::ASCIIString)](RCall.md#method__sexp.2)  Create a `CharSxp` from a String.

[sexp(::Type{RCall.ClosSxp},  f)](RCall.md#method__sexp.3)  Wrap a callable Julia object `f` an a R `ClosSxpPtr`.

[sexp(::Type{RCall.ExtPtrSxp},  j)](RCall.md#method__sexp.4)  Wrap a Julia object an a R `ExtPtrSxpPtr`.

[sexp(::Type{RCall.StrSxp},  s::Ptr{RCall.CharSxp})](RCall.md#method__sexp.5)  Create a `StrSxp` from an `AbstractString`

[sexp(::Type{RCall.SymSxp},  s::AbstractString)](RCall.md#method__sexp.6)  Create a `SymSxp` from a `Symbol`

[sexp(p::Ptr{RCall.SxpHead})](RCall.md#method__sexp.7)  Convert a `UnknownSxpPtr` to an approptiate `SxpPtr`.

[sexp(s::Symbol)](RCall.md#method__sexp.8)  Generic function for constructing Sxps from Julia objects.

[sexp_arglist_dots(args...)](RCall.md#method__sexp_arglist_dots.1)  Create an argument list for an R function call, with a varargs "dots" at the end.

[sexpnum(h::RCall.SxpHead)](RCall.md#method__sexpnum.1)  The SEXPTYPE number of a `Sxp`

[unprotect(n::Integer)](RCall.md#method__unprotect.1)  Release last `n` objects gc-protected by `protect`.

[unsafe_array{S<:RCall.VectorSxp}(s::Ptr{S<:RCall.VectorSxp})](RCall.md#method__unsafe_array.1)  The same as `unsafe_vec`, except returns an appropriately sized array.

[unsafe_vec{S<:RCall.VectorSxp}(s::Ptr{S<:RCall.VectorSxp})](RCall.md#method__unsafe_vec.1)  Represent the contents of a VectorSxp type as a `Vector`.

---

## Types [Internal]

[RCall.AnySxp](RCall.md#type__anysxp.1)  R "any" object

[RCall.BcodeSxp](RCall.md#type__bcodesxp.1)  R byte code

[RCall.BuiltinSxp](RCall.md#type__builtinsxp.1)  R built-in function

[RCall.DotSxp](RCall.md#type__dotsxp.1)  R dot-dot-dot object

[RCall.EnvSxp](RCall.md#type__envsxp.1)  R environment

[RCall.ExprSxp](RCall.md#type__exprsxp.1)  R expression vector

[RCall.ExtPtrSxp](RCall.md#type__extptrsxp.1)  R external pointer

[RCall.LangSxp](RCall.md#type__langsxp.1)  R function call

[RCall.ListSxp](RCall.md#type__listsxp.1)  R pairs (cons) list cell

[RCall.PromSxp](RCall.md#type__promsxp.1)  R promise

[RCall.RawSxp](RCall.md#type__rawsxp.1)  R byte vector

[RCall.S4Sxp](RCall.md#type__s4sxp.1)  R S4 object

[RCall.SpecialSxp](RCall.md#type__specialsxp.1)  R special function

[RCall.SxpHead](RCall.md#type__sxphead.1)  R Sxp header: a pointer to this is used for unknown types.

[RCall.SymSxp](RCall.md#type__symsxp.1)  R symbol

[RCall.VecSxp](RCall.md#type__vecsxp.1)  R list (i.e. Array{Any,1})

[RCall.WeakRefSxp](RCall.md#type__weakrefsxp.1)  R weak reference

---

## Globals [Internal]

[jtypExtPtrs](RCall.md#global__jtypextptrs.1)  Julia types (typically functions) which are wrapped in `ExtPtrSxpPtr` are

[typs](RCall.md#global__typs.1)  vector of R Sxp types

