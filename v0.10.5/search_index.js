var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Introduction",
    "title": "Introduction",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#RCall.jl-1",
    "page": "Introduction",
    "title": "RCall.jl",
    "category": "section",
    "text": "R is a language for statistical computing and graphics that has been around for couple of decades and it has one of the most impressive collections of scientific and statistical packages of any environment. Recently, the Julia language has become an attractive alternative because it provides the remarkable performance of a low-level language without sacrificing the readability and ease-of-use of high-level languages. However, Julia still lacks the depth and scale of the R package environment.This package, RCall, facilitates communication between these two languages and allows the user to call R packages from within Julia, providing the best of both worlds. Additionally, this is a pure Julia package so it is portable and easy to use."
},

{
    "location": "installation.html#",
    "page": "Installation",
    "title": "Installation",
    "category": "page",
    "text": ""
},

{
    "location": "installation.html#Installing-RCall.jl-1",
    "page": "Installation",
    "title": "Installing RCall.jl",
    "category": "section",
    "text": "RCall.jl can simply be installed withPkg.add(\"RCall\")RCall.jl will automatically install R for you using Conda if it doesn\'t detect that you have R 3.4.0 or later installed already."
},

{
    "location": "installation.html#Customizing-the-R-installation-1",
    "page": "Installation",
    "title": "Customizing the R installation",
    "category": "section",
    "text": "Before installing its own copy of R, the RCall build script (run by Pkg.add) will check for an existing R installation by looking in the following locations, in order.The R_HOME environment variable, if set, should be the location of the R home directory.\nOtherwise, it runs the R HOME command, assuming R is located in your PATH.\nOtherwise, on Windows, it looks in the Windows registry.\nOtherwise, it installs the r-base package.To change which R installation is used for RCall, set the R_HOME environment variable and run Pkg.build(\"RCall\").   Once this is configured, RCall remembers the location of R in future updates, so you don\'t need to set R_HOME permanently.You can set R_HOME to the empty string \"\" to force Pkg.build to re-run the R HOME command, e.g. if you change your PATH:ENV[\"R_HOME\"]=\"\"\nENV[\"PATH\"]=\"....directory of R executable...\"\nPkg.build(\"RCall\")When R HOME doesn\'t return a valid R library or R_HOME is set to \"*\", RCall will use its own Conda installation of R.Should you experience problems with any of these methods, please open an issue."
},

{
    "location": "installation.html#Standard-installations-1",
    "page": "Installation",
    "title": "Standard installations",
    "category": "section",
    "text": "If you want to install R yourself, rather than relying on the automatic Conda installation, you can use one of the following options:"
},

{
    "location": "installation.html#Windows-1",
    "page": "Installation",
    "title": "Windows",
    "category": "section",
    "text": "The current Windows binary from CRAN."
},

{
    "location": "installation.html#OS-X-1",
    "page": "Installation",
    "title": "OS X",
    "category": "section",
    "text": "The CRAN .pkg or the homebrew/science tap."
},

{
    "location": "installation.html#Linux-1",
    "page": "Installation",
    "title": "Linux",
    "category": "section",
    "text": "Most Linux distributions allow installation of R from their package manager, however these are often out of date, and may not work with RCall.jl. We recommend that you use the updated repositories from CRAN."
},

{
    "location": "installation.html#Ubuntu-1",
    "page": "Installation",
    "title": "Ubuntu",
    "category": "section",
    "text": "The following will update R on recent versions of Ubuntu:sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9\nsudo add-apt-repository -y \"deb http://cran.rstudio.com/bin/linux/ubuntu $(lsb_release -s -c)/\"\nsudo apt-get update -y\nsudo apt-get install -y r-base r-base-dev"
},

{
    "location": "installation.html#Other-methods-1",
    "page": "Installation",
    "title": "Other methods",
    "category": "section",
    "text": "If you have installed R by some other method (e.g. building from scratch, or files copied but not installed in the usual manner), which often happens on cluster installations, then you may need to set R_HOME or your PATH as described above before running Pkg.build(\"RCall\") in order for the build script to find your R installation."
},

{
    "location": "installation.html#Updating-R-1",
    "page": "Installation",
    "title": "Updating R",
    "category": "section",
    "text": "If you have updated your R installation, you may need to re-run Pkg.build(\"RCall\") as described above, possibly changing the R_HOME environment variable first."
},

{
    "location": "gettingstarted.html#",
    "page": "Getting Started",
    "title": "Getting Started",
    "category": "page",
    "text": ""
},

{
    "location": "gettingstarted.html#Getting-started-1",
    "page": "Getting Started",
    "title": "Getting started",
    "category": "section",
    "text": "The RCall package is loaded viausing RCallThis will initialize the R process in the background."
},

{
    "location": "gettingstarted.html#Several-Ways-to-use-RCall-1",
    "page": "Getting Started",
    "title": "Several Ways to use RCall",
    "category": "section",
    "text": "RCall provides multiple ways to allow R interacting with Julia. R REPL mode\n@rput and @rget macros\nR\"\" string macro\nRCall API: reval, rcall and rcopy etc."
},

{
    "location": "gettingstarted.html#R-REPL-mode-1",
    "page": "Getting Started",
    "title": "R REPL mode",
    "category": "section",
    "text": "The R REPL mode allows real time switching between the Julia prompt and R prompt. Press $ to activate the R REPL mode and the R prompt will be shown. (Press backspace to leave R REPL mode in case you did not know.)julia> foo = 1\n1\n\nR> x <- $foo\n\nR> x\n[1] 1The R REPL mode supports variable substitution of Julia objects via the $ symbol. It is also possible to pass Julia expressions in the REPL mode.R> x = $(rand(10))\n\nR> sum(x)\n[1] 5.097083"
},

{
    "location": "gettingstarted.html#@rput-and-@rget-macros-1",
    "page": "Getting Started",
    "title": "@rput and @rget macros",
    "category": "section",
    "text": "These macros transfer variables between R and Julia environments. The copied variable will have the same name as the original.julia> z = 1\n1\n\njulia> @rput z\n1\n\nR> z\n[1] 1\n\nR> r = 2\n\njulia> @rget r\n2.0\n\njulia> r\n2.0It is also possible to put and get multiple variables in one line.julia> foo = 2\n2\n\njulia> bar = 4\n4\n\njulia> @rput foo bar\n4\n\nR> foo + bar\n[1] 6"
},

{
    "location": "gettingstarted.html#@R_str-string-macro-1",
    "page": "Getting Started",
    "title": "@R_str string macro",
    "category": "section",
    "text": "Another way to use RCall is the R\"\" string macro, it is especially useful in script files.R\"rnorm(10)\"This evaluates the expression inside the string in R, and returns the result as an RObject, which is a Julia wrapper type around an R object.The R\"\" string macro supports variable substitution of Julia objects via the $ symbol, whenever it is not valid R syntax (i.e. when not directly following a symbol or completed expression such as aa$bb):x = randn(10)\nR\"t.test($x)\"It is also possible to pass Julia expressions which are evaluated before being passed to R: these should be included in parenthesesR\"optim(0, $(x -> x-cos(x)), method=\'BFGS\')\"A large chunk of code could be quoted between triple string quotationsy = 1\nR\"\"\"\nf <- function(x, y) x + y\nret <- f(1, $y)\n\"\"\""
},

{
    "location": "gettingstarted.html#RCall-API-1",
    "page": "Getting Started",
    "title": "RCall API",
    "category": "section",
    "text": "The reval function evaluates any given input string as R code in the R environment. The returned result is an RObject object.jmtcars = reval(\"mtcars\");\nnames(jmtcars)\njmtcars[:mpg]\ntypeof(jmtcars)The rcall function is used to construct function calls.rcall(:dim, jmtcars)The arguments will be implicitly converted to RObject upon evaluation.rcall(:sum, Float64[1.0, 4.0, 6.0])The rcopy function converts RObjects to Julia objects. It uses a variety of heuristics to pick the most appropriate Julia type:rcopy(R\"c(1)\")\nrcopy(R\"c(1, 2)\")\nrcopy(R\"list(1, \'zz\')\")\nrcopy(R\"list(a=1, b=\'zz\')\")It is possible to force a specific conversion by passing the output type as the first argument:rcopy(Array{Int}, R\"c(1,2)\")Converters and Constructors could also be used specifically to yield the desired type.convert(Array{Float64}, R\"c(1,2)\")\nFloat64(R\"1+3\")"
},

{
    "location": "conversions.html#",
    "page": "Supported Conversions",
    "title": "Supported Conversions",
    "category": "page",
    "text": ""
},

{
    "location": "conversions.html#Supported-Conversions-1",
    "page": "Supported Conversions",
    "title": "Supported Conversions",
    "category": "section",
    "text": "RCall supports conversions to and from most base Julia types and popular Statistics packages, e.g., DataFrames, DataArrays, NullableArrays, CategoricalArrays NamedArrays and AxisArrays.using RCall\nusing DataFrames\nusing NamedArrays\nusing AxisArrays"
},

{
    "location": "conversions.html#Base-Julia-Types-1",
    "page": "Supported Conversions",
    "title": "Base Julia Types",
    "category": "section",
    "text": "# Julia -> R\na = RObject(1)# R -> Julia\nrcopy(a)# Julia -> R\na = RObject([1.0, 2.0])# R -> Julia\nrcopy(a)"
},

{
    "location": "conversions.html#Dictionaries-1",
    "page": "Supported Conversions",
    "title": "Dictionaries",
    "category": "section",
    "text": "# Julia -> R\nd = Dict(:a => 1, :b => [4, 5, 3])\nr = RObject(d)# R -> Julia\nrcopy(r)"
},

{
    "location": "conversions.html#Date-1",
    "page": "Supported Conversions",
    "title": "Date",
    "category": "section",
    "text": "# Julia -> R\nd = Date(2012, 12, 12)\nr = RObject(d)# R -> Julia\nrcopy(r)"
},

{
    "location": "conversions.html#DateTime-1",
    "page": "Supported Conversions",
    "title": "DateTime",
    "category": "section",
    "text": "# julia -> R\nd = DateTime(2012, 12, 12, 12, 12, 12)\nr = RObject(d)# R -> Julia\nrcopy(r)"
},

{
    "location": "conversions.html#DataFrames-1",
    "page": "Supported Conversions",
    "title": "DataFrames",
    "category": "section",
    "text": "d = DataFrame([[1.0, 4.5, 7.0]], [:x])\n# Julia -> R\nr = RObject(d)# R -> Julia\nrcopy(r)In default, the column names of R data frames are sanitized such that foo.bar would be replaced by foo_bar.rcopy(R\"data.frame(a.b = 1:3)\")To avoid the sanitization, use sanitize option.rcopy(R\"data.frame(a.b = 1:10)\"; sanitize = false)"
},

{
    "location": "conversions.html#DataArrays-1",
    "page": "Supported Conversions",
    "title": "DataArrays",
    "category": "section",
    "text": "# Julia -> R\naa = DataArray([1,2,3], [true, true, false])\nr = RObject(aa)# R -> Julia\nrcopy(DataArray, r)"
},

{
    "location": "conversions.html#AxisArrays-1",
    "page": "Supported Conversions",
    "title": "AxisArrays",
    "category": "section",
    "text": "# Julia -> R\naa = AxisArray([1,2,3], Axis{:id}([\"a\", \"b\", \"c\"]))\nr = RObject(aa)# R -> Julia\nrcopy(AxisArray, r)"
},

{
    "location": "custom.html#",
    "page": "Custom Conversion",
    "title": "Custom Conversion",
    "category": "page",
    "text": ""
},

{
    "location": "custom.html#Custom-Conversion-1",
    "page": "Custom Conversion",
    "title": "Custom Conversion",
    "category": "section",
    "text": "RCall supports an API for implicitly converting between R and Julia objects by means of rcopy and RObject.To illustrate the idea, we consider the following Julia typeusing RCalltype Foo\n    x::Float64\n    y::String\nendfoo = Foo(1.0, \"hello\") \nnothing # hide"
},

{
    "location": "custom.html#Julia-to-R-direction-1",
    "page": "Custom Conversion",
    "title": "Julia to R direction",
    "category": "section",
    "text": "The function RCall.sexp has to be overwritten to allow Julia to R conversion. sexp function takes a julia object and returns an SEXP object (pointer to [Sxp]).import RCall.sexp\n\nfunction sexp(f::Foo)\n    r = protect(sexp(Dict(:x => f.x, :y => f.y)))\n    setclass!(r, sexp(\"Bar\"))\n    unprotect(1)\n    r\nend\n\nroo = RObject(foo)\nnothing # hideRemark: RCall.protect and RCall.unprotect should be used to protect SEXP from being garbage collected."
},

{
    "location": "custom.html#R-to-Julia-direction-1",
    "page": "Custom Conversion",
    "title": "R to Julia direction",
    "category": "section",
    "text": "The function rcopy and rcopytype are responsible for conversions of this direction. First we define an explicit converter for VecSxp (SEXP for list)import RCall.rcopy\n\nfunction rcopy(::Type{Foo}, s::Ptr{VecSxp})\n    Foo(rcopy(Float64, s[:x]), rcopy(String, s[:y]))\nendThe convert function will dispatch the corresponding rcopy function when it is found.rcopy(Foo, roo)\nconvert(Foo, roo) # calls `rcopy`\nFoo(roo)\nnothing # hideTo allow the automatic conversion via rcopy(roo), the R class Bar has to be registered.import RCall: RClass, rcopytype\n\nrcopytype(::Type{RClass{:Bar}}, s::Ptr{VecSxp}) = Foo\nboo = rcopy(roo)\nnothing # hide"
},

{
    "location": "custom.html#Using-@rput-and-@rget-is-seamless-1",
    "page": "Custom Conversion",
    "title": "Using @rput and @rget is seamless",
    "category": "section",
    "text": "boo.x = 2.0\n@rput boo\nR\"\"\"\nboo[\"x\"]\n\"\"\"R\"\"\"\nboo[\"x\"] = 3.0\n\"\"\"\n@rget boo\nboo.x"
},

{
    "location": "custom.html#Nested-conversion-1",
    "page": "Custom Conversion",
    "title": "Nested conversion",
    "category": "section",
    "text": "l = R\"list(boo = boo, roo = $roo)\"rcopy(l)"
},

{
    "location": "internal.html#",
    "page": "Internal",
    "title": "Internal",
    "category": "page",
    "text": ""
},

{
    "location": "internal.html#Internal-API-1",
    "page": "Internal",
    "title": "Internal API",
    "category": "section",
    "text": ""
},

{
    "location": "internal.html#RCall.CharSxp",
    "page": "Internal",
    "title": "RCall.CharSxp",
    "category": "type",
    "text": "R character string\n\n\n\n"
},

{
    "location": "internal.html#RCall.ClosSxp",
    "page": "Internal",
    "title": "RCall.ClosSxp",
    "category": "type",
    "text": "R function closure\n\n\n\n"
},

{
    "location": "internal.html#RCall.CplxSxp",
    "page": "Internal",
    "title": "RCall.CplxSxp",
    "category": "type",
    "text": "R complex vector\n\n\n\n"
},

{
    "location": "internal.html#RCall.EnvSxp",
    "page": "Internal",
    "title": "RCall.EnvSxp",
    "category": "type",
    "text": "R environment\n\n\n\n"
},

{
    "location": "internal.html#RCall.IntSxp",
    "page": "Internal",
    "title": "RCall.IntSxp",
    "category": "type",
    "text": "R integer vector\n\n\n\n"
},

{
    "location": "internal.html#RCall.LangSxp",
    "page": "Internal",
    "title": "RCall.LangSxp",
    "category": "type",
    "text": "R function call\n\n\n\n"
},

{
    "location": "internal.html#RCall.LglSxp",
    "page": "Internal",
    "title": "RCall.LglSxp",
    "category": "type",
    "text": "R logical vector\n\n\n\n"
},

{
    "location": "internal.html#RCall.ListSxp",
    "page": "Internal",
    "title": "RCall.ListSxp",
    "category": "type",
    "text": "R pairs (cons) list cell\n\n\n\n"
},

{
    "location": "internal.html#RCall.NilSxp",
    "page": "Internal",
    "title": "RCall.NilSxp",
    "category": "type",
    "text": "R NULL value\n\n\n\n"
},

{
    "location": "internal.html#RCall.RObject",
    "page": "Internal",
    "title": "RCall.RObject",
    "category": "type",
    "text": "An RObject is a Julia wrapper for an R object (known as an \"S-expression\" or \"SEXP\"). It is stored as a pointer which is protected from the R garbage collector, until the RObject itself is finalized by Julia. The parameter is the type of the S-expression.\n\nWhen called with a Julia object as an argument, a corresponding R object is constructed.\n\njulia> RObject(1)\nRObject{IntSxp}\n[1] 1\n\njulia> RObject(1:3)\nRObject{IntSxp}\n[1] 1 2 3\n\njulia> RObject(1.0:3.0)\nRObject{RealSxp}\n[1] 1 2 3\n\n\n\n"
},

{
    "location": "internal.html#RCall.RObject-Tuple{Any}",
    "page": "Internal",
    "title": "RCall.RObject",
    "category": "method",
    "text": "sexp(x) converts a Julia object x to a pointer to a corresponding Sxp Object.\n\n\n\n"
},

{
    "location": "internal.html#RCall.RealSxp",
    "page": "Internal",
    "title": "RCall.RealSxp",
    "category": "type",
    "text": "R real vector\n\n\n\n"
},

{
    "location": "internal.html#RCall.S4Sxp",
    "page": "Internal",
    "title": "RCall.S4Sxp",
    "category": "type",
    "text": "R S4 object\n\n\n\n"
},

{
    "location": "internal.html#RCall.StrSxp",
    "page": "Internal",
    "title": "RCall.StrSxp",
    "category": "type",
    "text": "R vector of character strings\n\n\n\n"
},

{
    "location": "internal.html#RCall.Sxp",
    "page": "Internal",
    "title": "RCall.Sxp",
    "category": "type",
    "text": "RCall.jl\'s type Sxp mirrors the R symbolic expression record SEXPREC in R API. These are represented by a pointer Ptr{S<:Sxp} (which is called SEXP in R API).\n\n\n\n"
},

{
    "location": "internal.html#RCall.VecSxp",
    "page": "Internal",
    "title": "RCall.VecSxp",
    "category": "type",
    "text": "R list (i.e. Array{Any,1})\n\n\n\n"
},

{
    "location": "internal.html#RCall.AnySxp",
    "page": "Internal",
    "title": "RCall.AnySxp",
    "category": "type",
    "text": "R \"any\" object\n\n\n\n"
},

{
    "location": "internal.html#RCall.BcodeSxp",
    "page": "Internal",
    "title": "RCall.BcodeSxp",
    "category": "type",
    "text": "R byte code\n\n\n\n"
},

{
    "location": "internal.html#RCall.BuiltinSxp",
    "page": "Internal",
    "title": "RCall.BuiltinSxp",
    "category": "type",
    "text": "R built-in function\n\n\n\n"
},

{
    "location": "internal.html#RCall.DotSxp",
    "page": "Internal",
    "title": "RCall.DotSxp",
    "category": "type",
    "text": "R dot-dot-dot object\n\n\n\n"
},

{
    "location": "internal.html#RCall.ExprSxp",
    "page": "Internal",
    "title": "RCall.ExprSxp",
    "category": "type",
    "text": "R expression vector\n\n\n\n"
},

{
    "location": "internal.html#RCall.ExtPtrSxp",
    "page": "Internal",
    "title": "RCall.ExtPtrSxp",
    "category": "type",
    "text": "R external pointer\n\n\n\n"
},

{
    "location": "internal.html#RCall.PromSxp",
    "page": "Internal",
    "title": "RCall.PromSxp",
    "category": "type",
    "text": "R promise\n\n\n\n"
},

{
    "location": "internal.html#RCall.RawSxp",
    "page": "Internal",
    "title": "RCall.RawSxp",
    "category": "type",
    "text": "R byte vector\n\n\n\n"
},

{
    "location": "internal.html#RCall.SpecialSxp",
    "page": "Internal",
    "title": "RCall.SpecialSxp",
    "category": "type",
    "text": "R special function\n\n\n\n"
},

{
    "location": "internal.html#RCall.SxpHead",
    "page": "Internal",
    "title": "RCall.SxpHead",
    "category": "type",
    "text": "R Sxp header: a pointer to this is used for unknown types.\n\n\n\n"
},

{
    "location": "internal.html#RCall.SymSxp",
    "page": "Internal",
    "title": "RCall.SymSxp",
    "category": "type",
    "text": "R symbol\n\n\n\n"
},

{
    "location": "internal.html#RCall.WeakRefSxp",
    "page": "Internal",
    "title": "RCall.WeakRefSxp",
    "category": "type",
    "text": "R weak reference\n\n\n\n"
},

{
    "location": "internal.html#Types-1",
    "page": "Internal",
    "title": "Types",
    "category": "section",
    "text": "Modules = [RCall]\nOrder   = [:type]"
},

{
    "location": "internal.html#DataArrays.anyna-Union{Tuple{RCall.RObject{S}}, Tuple{S}} where S<:RCall.VectorSxp",
    "page": "Internal",
    "title": "DataArrays.anyna",
    "category": "method",
    "text": "Check if there are any NA values in the vector.\n\n\n\n"
},

{
    "location": "internal.html#DataArrays.isna-Tuple{RCall.RObject,Integer}",
    "page": "Internal",
    "title": "DataArrays.isna",
    "category": "method",
    "text": "Check if the ith member of s coorespond to R\'s NA values.\n\n\n\n"
},

{
    "location": "internal.html#DataArrays.isna-Tuple{RCall.RObject}",
    "page": "Internal",
    "title": "DataArrays.isna",
    "category": "method",
    "text": "Check if the members of a vector are NA values. Always return a BitArray.\n\n\n\n"
},

{
    "location": "internal.html#RCall.getattrib-Union{Tuple{Ptr{S},Ptr{RCall.SymSxp}}, Tuple{S}} where S<:RCall.Sxp",
    "page": "Internal",
    "title": "RCall.getattrib",
    "category": "method",
    "text": "Return a particular attribute of an RObject\n\n\n\n"
},

{
    "location": "internal.html#RCall.getclass-Union{Tuple{Ptr{S},Bool}, Tuple{Ptr{S}}, Tuple{S}} where S<:RCall.Sxp",
    "page": "Internal",
    "title": "RCall.getclass",
    "category": "method",
    "text": "Returns the class of an R object.\n\n\n\n"
},

{
    "location": "internal.html#RCall.getnames-Union{Tuple{Ptr{S}}, Tuple{S}} where S<:RCall.Sxp",
    "page": "Internal",
    "title": "RCall.getnames",
    "category": "method",
    "text": "Returns the names of an R vector.\n\n\n\n"
},

{
    "location": "internal.html#RCall.rcall-Tuple{Any,Vararg{Any,N} where N}",
    "page": "Internal",
    "title": "RCall.rcall",
    "category": "method",
    "text": "Evaluate a function in the global environment. The first argument corresponds to the function to be called. It can be either a FunctionSxp type, a SymSxp or a Symbol.\n\n\n\n"
},

{
    "location": "internal.html#RCall.rcopy-Union{Tuple{RCall.RObject{S}}, Tuple{S}} where S<:RCall.Sxp",
    "page": "Internal",
    "title": "RCall.rcopy",
    "category": "method",
    "text": "rcopy(r) copies the contents of an R object into a corresponding canonical Julia type.\n\n\n\n"
},

{
    "location": "internal.html#RCall.reval",
    "page": "Internal",
    "title": "RCall.reval",
    "category": "function",
    "text": "Evaluate an R symbol or language object (i.e. a function call) in an R try/catch block, returning an RObject.\n\n\n\n"
},

{
    "location": "internal.html#RCall.rimport",
    "page": "Internal",
    "title": "RCall.rimport",
    "category": "function",
    "text": "Import an R package as a julia module.\n\ngg = rimport(\"ggplot2\")\n\n\n\n"
},

{
    "location": "internal.html#RCall.rlang-Tuple{Any,Vararg{Any,N} where N}",
    "page": "Internal",
    "title": "RCall.rlang",
    "category": "method",
    "text": "Create a function call from a function pointer and a list of arguments and return it as an RObject, which can then be evaulated\n\n\n\n"
},

{
    "location": "internal.html#RCall.rparse-Tuple{AbstractString}",
    "page": "Internal",
    "title": "RCall.rparse",
    "category": "method",
    "text": "Parse a string as an R expression, returning an RObject.\n\n\n\n"
},

{
    "location": "internal.html#RCall.rprint-Union{Tuple{IO,Ptr{S}}, Tuple{S}} where S<:RCall.Sxp",
    "page": "Internal",
    "title": "RCall.rprint",
    "category": "method",
    "text": "Print the value of an Sxp using R\'s printing mechanism\n\n\n\n"
},

{
    "location": "internal.html#RCall.setattrib!-Union{Tuple{Ptr{S},Ptr{RCall.SymSxp},Ptr{T}}, Tuple{S}, Tuple{T}} where T<:RCall.Sxp where S<:RCall.Sxp",
    "page": "Internal",
    "title": "RCall.setattrib!",
    "category": "method",
    "text": "Set a particular attribute of an RObject\n\n\n\n"
},

{
    "location": "internal.html#RCall.setclass!-Union{Tuple{Ptr{S},Ptr{RCall.StrSxp}}, Tuple{S}} where S<:RCall.Sxp",
    "page": "Internal",
    "title": "RCall.setclass!",
    "category": "method",
    "text": "Set the class of an R object.\n\n\n\n"
},

{
    "location": "internal.html#RCall.setnames!-Union{Tuple{Ptr{S},Ptr{RCall.StrSxp}}, Tuple{S}} where S<:RCall.Sxp",
    "page": "Internal",
    "title": "RCall.setnames!",
    "category": "method",
    "text": "Set the names of an R vector.\n\n\n\n"
},

{
    "location": "internal.html#Base.eltype-Tuple{Type{RCall.LglSxp}}",
    "page": "Internal",
    "title": "Base.eltype",
    "category": "method",
    "text": "Element types of R vectors.\n\n\n\n"
},

{
    "location": "internal.html#Base.getindex-Tuple{Ptr{RCall.EnvSxp},Ptr{RCall.SymSxp}}",
    "page": "Internal",
    "title": "Base.getindex",
    "category": "method",
    "text": "extract the value of symbol s in the environment e\n\n\n\n"
},

{
    "location": "internal.html#Base.getindex-Tuple{Ptr{RCall.S4Sxp},Ptr{RCall.SymSxp}}",
    "page": "Internal",
    "title": "Base.getindex",
    "category": "method",
    "text": "extract an element from a S4Sxp by label\n\n\n\n"
},

{
    "location": "internal.html#Base.getindex-Union{Tuple{Ptr{S},AbstractString}, Tuple{S}} where S<:RCall.PairListSxp",
    "page": "Internal",
    "title": "Base.getindex",
    "category": "method",
    "text": "extract an element from a PairListSxp by label\n\n\n\n"
},

{
    "location": "internal.html#Base.getindex-Union{Tuple{Ptr{S},AbstractString}, Tuple{S}} where S<:RCall.VectorSxp",
    "page": "Internal",
    "title": "Base.getindex",
    "category": "method",
    "text": "String indexing finds the first element with the matching name\n\n\n\n"
},

{
    "location": "internal.html#Base.getindex-Union{Tuple{Ptr{S},Integer}, Tuple{S}} where S<:RCall.PairListSxp",
    "page": "Internal",
    "title": "Base.getindex",
    "category": "method",
    "text": "extract the i-th element of a PairListSxp\n\n\n\n"
},

{
    "location": "internal.html#Base.getindex-Union{Tuple{Ptr{S},Integer}, Tuple{S}} where S<:RCall.VectorAtomicSxp",
    "page": "Internal",
    "title": "Base.getindex",
    "category": "method",
    "text": "Indexing into VectorSxp types uses Julia indexing into the vec result, except for StrSxp and the VectorListSxp types, which must apply sexp to the Ptr{Void} obtained by indexing into the vec result.\n\n\n\n"
},

{
    "location": "internal.html#Base.isascii-Tuple{RCall.CharSxp}",
    "page": "Internal",
    "title": "Base.isascii",
    "category": "method",
    "text": "Determines the encoding of the CharSxp. This is determined by the \'gp\' part of the sxpinfo (this is the middle 16 bits).\n\n0x00_0002_00 (bit 1): set of bytes (no known encoding)\n0x00_0004_00 (bit 2): Latin-1\n0x00_0008_00 (bit 3): UTF-8\n0x00_0040_00 (bit 6): ASCII\n\nWe only support ASCII and UTF-8.\n\n\n\n"
},

{
    "location": "internal.html#Base.isnull-Tuple{RCall.RObject}",
    "page": "Internal",
    "title": "Base.isnull",
    "category": "method",
    "text": "Check if values correspond to R\'s NULL object.\n\n\n\n"
},

{
    "location": "internal.html#Base.length-Union{Tuple{Ptr{S}}, Tuple{S}} where S<:RCall.Sxp",
    "page": "Internal",
    "title": "Base.length",
    "category": "method",
    "text": "Sxp methods for length return the R length.\n\nRf_xlength handles Sxps that are not vector-like and R\'s \"long vectors\", which have a negative value for the length member.\n\n\n\n"
},

{
    "location": "internal.html#Base.names-Tuple{RCall.RObject}",
    "page": "Internal",
    "title": "Base.names",
    "category": "method",
    "text": "Returns the names of an R vector, the result is converted to a Julia symbol array.\n\n\n\n"
},

{
    "location": "internal.html#Base.setindex!-Union{Tuple{Ptr{RCall.EnvSxp},Ptr{S},Ptr{RCall.StrSxp}}, Tuple{S}} where S<:RCall.Sxp",
    "page": "Internal",
    "title": "Base.setindex!",
    "category": "method",
    "text": "assign value v to symbol s in the environment e\n\n\n\n"
},

{
    "location": "internal.html#Base.setindex!-Union{Tuple{Ptr{RCall.S4Sxp},Ptr{T},Ptr{RCall.SymSxp}}, Tuple{T}} where T<:RCall.Sxp",
    "page": "Internal",
    "title": "Base.setindex!",
    "category": "method",
    "text": "extract an element from a S4Sxp by label\n\n\n\n"
},

{
    "location": "internal.html#Base.setindex!-Union{Tuple{Ptr{S},Ptr{T},AbstractString}, Tuple{S}, Tuple{T}} where T<:RCall.Sxp where S<:RCall.PairListSxp",
    "page": "Internal",
    "title": "Base.setindex!",
    "category": "method",
    "text": "Set element of a PairListSxp by a label.\n\n\n\n"
},

{
    "location": "internal.html#Base.setindex!-Union{Tuple{Ptr{S},Ptr{T},AbstractString}, Tuple{S}, Tuple{T}} where T<:RCall.Sxp where S<:RCall.VectorSxp",
    "page": "Internal",
    "title": "Base.setindex!",
    "category": "method",
    "text": "Set element of a VectorSxp by a label.\n\n\n\n"
},

{
    "location": "internal.html#Base.setindex!-Union{Tuple{Ptr{S},Ptr{T},Integer}, Tuple{S}, Tuple{T}} where T<:RCall.Sxp where S<:RCall.PairListSxp",
    "page": "Internal",
    "title": "Base.setindex!",
    "category": "method",
    "text": "assign value v to the i-th element of a PairListSxp\n\n\n\n"
},

{
    "location": "internal.html#Base.size-Union{Tuple{Ptr{S}}, Tuple{S}} where S<:RCall.Sxp",
    "page": "Internal",
    "title": "Base.size",
    "category": "method",
    "text": "Returns the size of an R object.\n\n\n\n"
},

{
    "location": "internal.html#RCall.bound-Union{Tuple{Ptr{S}}, Tuple{S}} where S<:RCall.Sxp",
    "page": "Internal",
    "title": "RCall.bound",
    "category": "method",
    "text": "The R NAMED property, represented by 2 bits in the info field. This can take values 0,1 or 2, corresponding to whether it is bound to 0,1 or 2 or more symbols. See http://cran.r-project.org/doc/manuals/r-patched/R-exts.html#Named-objects-and-copying\n\n\n\n"
},

{
    "location": "internal.html#RCall.dataptr-Union{Tuple{Ptr{S}}, Tuple{S}} where S<:RCall.VectorSxp",
    "page": "Internal",
    "title": "RCall.dataptr",
    "category": "method",
    "text": "Pointer to start of the data array in a SEXPREC. Corresponds to DATAPTR C macro.\n\n\n\n"
},

{
    "location": "internal.html#RCall.decref_extptr-Tuple{Ptr{RCall.ExtPtrSxp}}",
    "page": "Internal",
    "title": "RCall.decref_extptr",
    "category": "method",
    "text": "Called by the R finalizer.\n\n\n\n"
},

{
    "location": "internal.html#RCall.endEmbeddedR-Tuple{}",
    "page": "Internal",
    "title": "RCall.endEmbeddedR",
    "category": "method",
    "text": "endEmbeddedR()\n\nClose embedded R session.\n\n\n\n"
},

{
    "location": "internal.html#RCall.event_callback-Tuple{}",
    "page": "Internal",
    "title": "RCall.event_callback",
    "category": "method",
    "text": "Event Callback: allows R to process Julia events when R is busy. For example, writing output to STDOUT while running an expensive R command.\n\n\n\n"
},

{
    "location": "internal.html#RCall.findNamespace-Tuple{String}",
    "page": "Internal",
    "title": "RCall.findNamespace",
    "category": "method",
    "text": "find namespace by name of the namespace, it is not error tolerant.\n\n\n\n"
},

{
    "location": "internal.html#RCall.getNamespace-Tuple{String}",
    "page": "Internal",
    "title": "RCall.getNamespace",
    "category": "method",
    "text": "get namespace by name of the namespace. It is safer to be used than findNamespace as it checks bound.\n\n\n\n"
},

{
    "location": "internal.html#RCall.getParseErrorMsg-Tuple{}",
    "page": "Internal",
    "title": "RCall.getParseErrorMsg",
    "category": "method",
    "text": "Get the R parser error msg for the previous parsing result.\n\n\n\n"
},

{
    "location": "internal.html#RCall.ijulia_displayplots-Tuple{}",
    "page": "Internal",
    "title": "RCall.ijulia_displayplots",
    "category": "method",
    "text": "Called after cell evaluation. Closes graphics device and displays files in notebook.\n\n\n\n"
},

{
    "location": "internal.html#RCall.ijulia_setdevice-Tuple{MIME}",
    "page": "Internal",
    "title": "RCall.ijulia_setdevice",
    "category": "method",
    "text": "Set options for R plotting with IJulia.\n\nThe first argument should be a MIME object: currently supported are\n\nMIME(\"image/png\") [default]\nMIME(\"image/svg+xml\")\n\nThe remaining arguments (keyword only) are passed to the appropriate R graphics device: see the relevant R help for details.\n\n\n\n"
},

{
    "location": "internal.html#RCall.initEmbeddedR-Tuple{}",
    "page": "Internal",
    "title": "RCall.initEmbeddedR",
    "category": "method",
    "text": "initEmbeddedR()\n\nThis initializes an embedded R session. It should only be called when R is not already running (e.g. if Julia is running inside an R session)\n\n\n\n"
},

{
    "location": "internal.html#RCall.isNA-Tuple{Complex{Float64}}",
    "page": "Internal",
    "title": "RCall.isNA",
    "category": "method",
    "text": "Check if a value corresponds to R\'s sentinel NA values. These function should not be exported.\n\n\n\n"
},

{
    "location": "internal.html#RCall.julia_extptr_callback-Tuple{Ptr{RCall.ListSxp}}",
    "page": "Internal",
    "title": "RCall.julia_extptr_callback",
    "category": "method",
    "text": "The function called by R .External for Julia callbacks.\n\nIt receives a Ptr{ListSxp} containing\n\na pointer to the function itself (Ptr{ExtPtrSxp})\na pointer to the Julia function (Ptr{ExtPtrSxp})\nany arguments (as Ptr{S<:Sxp})\n\n\n\n"
},

{
    "location": "internal.html#RCall.makeExternalPtr",
    "page": "Internal",
    "title": "RCall.makeExternalPtr",
    "category": "function",
    "text": "Create an Ptr{ExtPtrSxp} object\n\n\n\n"
},

{
    "location": "internal.html#RCall.makeNativeSymbolRef-Tuple{Ptr{Void}}",
    "page": "Internal",
    "title": "RCall.makeNativeSymbolRef",
    "category": "method",
    "text": "Register a function pointer as an R NativeSymbol. We technically are supposed to use R_registerRoutines. Starting from R 3.4, R_MakeExternalPtrFn is a part of R API in R 3.4. It is probably safe to such to make the external pointer.\n\n\n\n"
},

{
    "location": "internal.html#RCall.naeltype-Tuple{Type{RCall.LglSxp}}",
    "page": "Internal",
    "title": "RCall.naeltype",
    "category": "method",
    "text": "NA element for each type\n\n\n\n"
},

{
    "location": "internal.html#RCall.newEnvironment-Tuple{Ptr{RCall.EnvSxp}}",
    "page": "Internal",
    "title": "RCall.newEnvironment",
    "category": "method",
    "text": "newEnvironment([env])\n\nCreate a new environment which extends environment env (globalEnv by default).\n\n\n\n"
},

{
    "location": "internal.html#RCall.parseVector-Union{Tuple{Ptr{RCall.StrSxp},Ref{Int32},Ptr{S}}, Tuple{Ptr{RCall.StrSxp},Ref{Int32}}, Tuple{S}} where S<:RCall.Sxp",
    "page": "Internal",
    "title": "RCall.parseVector",
    "category": "method",
    "text": "A pure julia wrapper of R_ParseVector\n\n\n\n"
},

{
    "location": "internal.html#RCall.prepare_inline_julia_code",
    "page": "Internal",
    "title": "RCall.prepare_inline_julia_code",
    "category": "function",
    "text": "Prepare code for evaluating the julia expressions. When the code is execulated, the results are stored in the R environment #JL.\n\n\n\n"
},

{
    "location": "internal.html#RCall.preserve-Union{Tuple{Ptr{S}}, Tuple{S}} where S<:RCall.Sxp",
    "page": "Internal",
    "title": "RCall.preserve",
    "category": "method",
    "text": "Prevent garbage collection of an R object. Object can be released via release.\n\nThis is slower than protect, as it requires searching an internal list, but more flexible.\n\n\n\n"
},

{
    "location": "internal.html#RCall.protect-Union{Tuple{Ptr{S}}, Tuple{S}} where S<:RCall.Sxp",
    "page": "Internal",
    "title": "RCall.protect",
    "category": "method",
    "text": "Stack-based protection of garbage collection of R objects. Objects are released via unprotect. Returns the same pointer, allowing inline use.\n\nThis is faster than preserve, but more restrictive. Really only useful inside functions.\n\n\n\n"
},

{
    "location": "internal.html#RCall.rcall_p-Tuple{Any,Vararg{Any,N} where N}",
    "page": "Internal",
    "title": "RCall.rcall_p",
    "category": "method",
    "text": "Evaluate a function in the global environment. The first argument corresponds to the function to be called. It can be either a FunctionSxp type, a SymSxp or a Symbol.\n\n\n\n"
},

{
    "location": "internal.html#RCall.registerCFinalizerEx-Tuple{Ptr{RCall.ExtPtrSxp}}",
    "page": "Internal",
    "title": "RCall.registerCFinalizerEx",
    "category": "method",
    "text": "Register finalizer to be called by the R GC.\n\n\n\n"
},

{
    "location": "internal.html#RCall.release-Union{Tuple{Ptr{S}}, Tuple{S}} where S<:RCall.Sxp",
    "page": "Internal",
    "title": "RCall.release",
    "category": "method",
    "text": "Release object that has been gc protected by preserve.\n\n\n\n"
},

{
    "location": "internal.html#RCall.render-Tuple{String}",
    "page": "Internal",
    "title": "RCall.render",
    "category": "method",
    "text": "Render an inline R script, substituting invalid \"$(Expr(:incomplete, \"incomplete: invalid string syntax\"))\n\n\n\n"
},

{
    "location": "internal.html#RCall.reval_p-Tuple{Ptr{RCall.ExprSxp},Ptr{RCall.EnvSxp}}",
    "page": "Internal",
    "title": "RCall.reval_p",
    "category": "method",
    "text": "Evaluate an R expression array iteratively. If throw_error is false, the error message and warning will be thrown to STDERR.\n\n\n\n"
},

{
    "location": "internal.html#RCall.reval_p-Union{Tuple{Ptr{S},Ptr{RCall.EnvSxp}}, Tuple{Ptr{S}}, Tuple{S}} where S<:RCall.Sxp",
    "page": "Internal",
    "title": "RCall.reval_p",
    "category": "method",
    "text": "Evaluate an R symbol or language object (i.e. a function call) in an R try/catch block, returning a Sxp pointer.\n\n\n\n"
},

{
    "location": "internal.html#RCall.rlang_p-Tuple{Any,Vararg{Any,N} where N}",
    "page": "Internal",
    "title": "RCall.rlang_p",
    "category": "method",
    "text": "Create a function call from a list of arguments\n\n\n\n"
},

{
    "location": "internal.html#RCall.rparse_p-Union{Tuple{Ptr{RCall.StrSxp},Ptr{S}}, Tuple{Ptr{RCall.StrSxp}}, Tuple{S}} where S<:RCall.Sxp",
    "page": "Internal",
    "title": "RCall.rparse_p",
    "category": "method",
    "text": "Parse a string as an R expression, returning a Sxp pointer.\n\n\n\n"
},

{
    "location": "internal.html#RCall.set_last_value-Union{Tuple{Ptr{S}}, Tuple{S}} where S<:RCall.Sxp",
    "page": "Internal",
    "title": "RCall.set_last_value",
    "category": "method",
    "text": "Set the variable .Last.value to a given value\n\n\n\n"
},

{
    "location": "internal.html#RCall.sexp-Tuple{Ptr{RCall.SxpHead}}",
    "page": "Internal",
    "title": "RCall.sexp",
    "category": "method",
    "text": "Convert a Ptr{UnknownSxp} to an approptiate Ptr{S<:Sxp}.\n\n\n\n"
},

{
    "location": "internal.html#RCall.sexp-Tuple{Type{RCall.ClosSxp},Any}",
    "page": "Internal",
    "title": "RCall.sexp",
    "category": "method",
    "text": "Wrap a callable Julia object f an a R ClosSxpPtr.\n\nConstructs the following R code\n\nfunction(...) .External(juliaCallback, fExPtr, ...)\n\n\n\n"
},

{
    "location": "internal.html#RCall.sexp-Tuple{Type{RCall.ExtPtrSxp},Any}",
    "page": "Internal",
    "title": "RCall.sexp",
    "category": "method",
    "text": "Wrap a Julia object an a R Ptr{ExtPtrSxp}.\n\nWe store the pointer and the object in a const Dict to prevent it being removed by the Julia GC.\n\n\n\n"
},

{
    "location": "internal.html#RCall.sexp_arglist_dots-Tuple",
    "page": "Internal",
    "title": "RCall.sexp_arglist_dots",
    "category": "method",
    "text": "Create an argument list for an R function call, with a varargs \"dots\" at the end.\n\n\n\n"
},

{
    "location": "internal.html#RCall.sexpnum-Tuple{RCall.SxpHead}",
    "page": "Internal",
    "title": "RCall.sexpnum",
    "category": "method",
    "text": "The SEXPTYPE number of a Sxp\n\nDetermined from the trailing 5 bits of the first 32-bit word. Is a 0-based index into the info field of a SxpHead.\n\n\n\n"
},

{
    "location": "internal.html#RCall.tryCatchError-Tuple{Function,Tuple,Function,Tuple}",
    "page": "Internal",
    "title": "RCall.tryCatchError",
    "category": "method",
    "text": "A wrapper of R_tryCatchError. It evaluates a given function with the given argument. It also catches possible R\'s stop calls which may cause longjmp in c. The error handler is evaluate when such an exception is caught.\n\n\n\n"
},

{
    "location": "internal.html#RCall.tryEval-Union{Tuple{Ptr{S},Ptr{RCall.EnvSxp},Ref{Int32}}, Tuple{Ptr{S},Ptr{RCall.EnvSxp}}, Tuple{Ptr{S}}, Tuple{S}} where S<:RCall.Sxp",
    "page": "Internal",
    "title": "RCall.tryEval",
    "category": "method",
    "text": "A pure julia wrapper of R_tryEval.\n\n\n\n"
},

{
    "location": "internal.html#RCall.unprotect-Tuple{Integer}",
    "page": "Internal",
    "title": "RCall.unprotect",
    "category": "method",
    "text": "Release last n objects gc-protected by protect.\n\n\n\n"
},

{
    "location": "internal.html#RCall.unsafe_array-Union{Tuple{Ptr{S}}, Tuple{S}} where S<:RCall.VectorSxp",
    "page": "Internal",
    "title": "RCall.unsafe_array",
    "category": "method",
    "text": "The same as unsafe_vec, except returns an appropriately sized array.\n\n\n\n"
},

{
    "location": "internal.html#RCall.unsafe_vec-Union{Tuple{Ptr{S}}, Tuple{S}} where S<:RCall.VectorSxp",
    "page": "Internal",
    "title": "RCall.unsafe_vec",
    "category": "method",
    "text": "Represent the contents of a VectorSxp type as a Vector.\n\nThis does __not__ copy the contents.  If the argument is not named (in R) or otherwise protected from R\'s garbage collection (e.g. by keeping the containing RObject in scope) the contents of this vector can be modified or could cause a memory error when accessed.\n\nThe contents are as stored in R.  Missing values (NA\'s) are represented in R by sentinels.  Missing data values in RealSxp and CplxSxp show up as NaN and NaN + NaNim, respectively.  Missing data in IntSxp show up as -2147483648, the minimum 32-bit integer value.  Internally a LglSxp is represented as Vector{Int32}.  The convention is that 0 is false, -2147483648 is NA and all other values represent true.\n\n\n\n"
},

{
    "location": "internal.html#RCall.validate_libR",
    "page": "Internal",
    "title": "RCall.validate_libR",
    "category": "function",
    "text": "validate_libR(libR, raise=true)\n\nChecks that the R library libR can be loaded and is satisfies version requirements.\n\nIf raise is set to false, then returns a boolean indicating success rather than throwing exceptions.\n\n\n\n"
},

{
    "location": "internal.html#RCall.write_console_ex-Tuple{Ptr{UInt8},Int32,Int32}",
    "page": "Internal",
    "title": "RCall.write_console_ex",
    "category": "method",
    "text": "R API callback to write console output.\n\n\n\n"
},

{
    "location": "internal.html#Methods-1",
    "page": "Internal",
    "title": "Methods",
    "category": "section",
    "text": "Modules = [RCall]\nOrder   = [:function]"
},

{
    "location": "internal.html#RCall.@R_str-Tuple{Any}",
    "page": "Internal",
    "title": "RCall.@R_str",
    "category": "macro",
    "text": "R\"...\"\n\nAn inline R expression, the result of which is evaluated and returned as an RObject.\n\nIt supports substitution of Julia variables and expressions via prefix with $ whenever not valid R syntax (i.e. when not immediately following another completed R expression):\n\nR\"glm(Sepal.Length ~ Sepal.Width, data=$iris)\"\n\nIt is also possible to pass Julia expressions:\n\nR\"plot(RCall.#98)\"\n\nAll such Julia expressions are evaluated once, before the R expression is evaluated.\n\nThe expression does not support assigning to Julia variables, so the only way retrieve values from R via the return value.\n\n\n\n"
},

{
    "location": "internal.html#RCall.@rget-Tuple",
    "page": "Internal",
    "title": "RCall.@rget",
    "category": "macro",
    "text": "Copies variables from R to Julia using the same name.\n\n\n\n"
},

{
    "location": "internal.html#RCall.@rimport-Tuple{Any,Vararg{Any,N} where N}",
    "page": "Internal",
    "title": "RCall.@rimport",
    "category": "macro",
    "text": "Import an R Package as a Julia module. For example,\n\n@rimport ggplot2\n\nis equivalent to ggplot2 = rimport(\"ggplot2\") with error checking.\n\nYou can also use classic Python syntax to make an alias: @rimport *package-name* as *shorthand*\n\n@rimport ggplot2 as gg\n\nwhich is equivalent to gg = rimport(\"ggplot2\").\n\n\n\n"
},

{
    "location": "internal.html#RCall.@rlibrary-Tuple{Any}",
    "page": "Internal",
    "title": "RCall.@rlibrary",
    "category": "macro",
    "text": "Load all exported functions/objects of an R package to the current module. Almost equivalent to\n\n__temp__ = rimport(\"ggplot2\")\nusing .__temp__\n\n\n\n"
},

{
    "location": "internal.html#RCall.@rput-Tuple",
    "page": "Internal",
    "title": "RCall.@rput",
    "category": "macro",
    "text": "Copies variables from Julia to R using the same name.\n\n\n\n"
},

{
    "location": "internal.html#RCall.@var_str-Tuple{Any}",
    "page": "Internal",
    "title": "RCall.@var_str",
    "category": "macro",
    "text": "Returns a variable named \"str\". Useful for passing keyword arguments containing dots.\n\n\n\n"
},

{
    "location": "internal.html#Macros-1",
    "page": "Internal",
    "title": "Macros",
    "category": "section",
    "text": "Modules = [RCall]\nOrder   = [:macro]"
},

{
    "location": "internal.html#RCall.globalEnv",
    "page": "Internal",
    "title": "RCall.globalEnv",
    "category": "constant",
    "text": "R global Environment.\n\nglobalEnv[:x] = 1\nglobalEnv[:x]\n\n\n\n"
},

{
    "location": "internal.html#RCall.jtypExtPtrs",
    "page": "Internal",
    "title": "RCall.jtypExtPtrs",
    "category": "constant",
    "text": "Julia types (typically functions) which are wrapped in Ptr{ExtPtrSxp} are stored here to prevent garbage collection by Julia.\n\n\n\n"
},

{
    "location": "internal.html#RCall.typs",
    "page": "Internal",
    "title": "RCall.typs",
    "category": "constant",
    "text": "vector of R Sxp types\n\n\n\n"
},

{
    "location": "internal.html#Constants-1",
    "page": "Internal",
    "title": "Constants",
    "category": "section",
    "text": "Modules = [RCall]\nOrder   = [:constant]"
},

]}
