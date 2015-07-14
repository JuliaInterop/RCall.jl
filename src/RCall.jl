module RCall
using Compat,DataArrays,DataFrames

if VERSION < v"v0.4-"
    using Docile                    # for the @doc macro
end

import Base: eltype, show, convert,
    length, size, getindex, setindex!, start, next, done

export RObject,
   Sxp, StrSxp, LglSxp, IntSxp, RealSxp, CplxSxp,
   getAttrib, setAttrib!, getNames, setNames!,
   rGlobalEnv,
   rcopy, rparse, rprint, reval, rcall, rlang,
   isNA, anyNA, isFactor, isOrdered,
   @rimport, @rusing


if isfile(joinpath(dirname(@__FILE__),"..","deps","deps.jl"))
    include("../deps/deps.jl")
else
    error("RCall not properly installed. Please run Pkg.build(\"RCall\")")
end


include("types.jl")
include("methods.jl")
include("conversions.jl")
include("dframes.jl")
include("iface.jl")
include("functions.jl")
include("library.jl")
include("eventloop.jl")
include("callback.jl")
include("IJulia.jl")
include("io.jl")


type Rinstance                    # attach a finalizer to clean up
    i::Cint
    function Rinstance(i::Integer)
        v = new(convert(Cint,i))
        finalizer(v,i->ccall((:Rf_endEmbeddedR,libR),Void,(Cint,),0))
        v
    end
end


function __init__()
    argv = ["REmbeddedJulia","--silent","--no-save"]
    i = ccall((:Rf_initEmbeddedR,libR),Cint,(Cint,Ptr{Ptr{Uint8}}),length(argv),argv)
    i > 0 || error("initEmbeddedR failed.  Try running Pkg.build(\"RCall\").")
    global const Rproc = Rinstance(i)


    ip = ccall((:Rf_ScalarInteger,libR),Ptr{Void},(Int32,),0)
    global const voffset = ccall((:INTEGER,libR),Ptr{Void},(Ptr{Void},),ip) - ip


    global const rNaInt =  unsafe_load(cglobal((:R_NaInt,libR),Cint))
    global const rNaReal = unsafe_load(cglobal((:R_NaReal,libR),Cdouble))

    global const rNaString = unsafe_load(cglobal((:R_NaString,libR),CharSxpPtr))
    global const rBlankString = unsafe_load(cglobal((:R_BlankString,libR),CharSxpPtr))
    global const rBlankScalarString = unsafe_load(cglobal((:R_BlankScalarString,libR),Ptr{StrSxp}))

    for s in [:BaseSymbol,         # base
              :BraceSymbol,        # {
              :Bracket2Symbol,     # [[
              :BracketSymbol,      # [
              :ClassSymbol,        # class
              :DeviceSymbol,       # .Device
              :DimNamesSymbol,     # dimnames
              :DimSymbol,          # dim
              :DollarSymbol,       # $
              :DotsSymbol,         # ...
              :DoubleColonSymbol,  # ::
              :DropSymbol,         # drop
              :LastvalueSymbol,    # .Last.value
              :LevelsSymbol,       # levels
              :ModeSymbol,         # mode
              :NaRmSymbol,         # na.rm
              :NameSymbol,         # name
              :NamesSymbol,        # names
              :NamespaceEnvSymbol, # .__NAMESPACE__.
              :PackageSymbol,      # package
              :PreviousSymbol,     # previous
              :QuoteSymbol,        # quote
              :RowNamesSymbol,     # row.names
              :SeedsSymbol,        # .Random.seed
              :SortListSymbol,     # sort.lis
              :SourceSymbol,       # source
              :SpecSymbol,         # spec
              :TripleColonSymbol,  # :::
              :dot_defined,        # .defined
              :dot_Method,         # .Method
              :dot_packageName,    # .packageName
              :dot_target]         # .targe

        @eval global const $(symbol(string('r',s))) = unsafe_load(cglobal(($(string(:R_,s)),libR),Ptr{SymSxp}))
    end

    global const rEmptyEnv = unsafe_load(cglobal((:R_EmptyEnv,libR),Ptr{EnvSxp}))
    global const rGlobalEnv = unsafe_load(cglobal((:R_GlobalEnv,libR),Ptr{EnvSxp}))

    global const rNilValue = unsafe_load(cglobal((:R_NilValue,libR),Ptr{NilSxp}))
    global const rUnboundValue = unsafe_load(cglobal((:R_UnboundValue,libR),UnknownSxpPtr))
    global const rMissingArg =  unsafe_load(cglobal((:R_MissingArg,libR),Ptr{SymSxp}))



    # set up function callbacks
    global const pJuliaCallback = cfunction(callJuliaExtPtr,UnknownSxpPtr,(ListSxpPtr,))
    global const rJuliaCallback = RObject(makeNativeSymbol(pJuliaCallback))
    global const pJuliaDecref = cfunction(decrefExtPtr,Void,(ExtPtrSxpPtr,))


    # printing
    pWriteConsoleEx = cfunction(writeConsoleEx,Void,(Ptr{UInt8},Cint,Cint))

    if OS_NAME == :Windows
		pCallBack = cfunction(eventCallBack,Void,())
		pYesNoCancel = cfunction(askYesNoCancel,Cint,(Ptr{Cchar},))
        rs = RStart()
        ccall((:R_DefParams,libR),Void,(Ptr{RStart},),&rs)
        rs.rhome = ccall((:get_R_HOME,libR),Ptr{Cchar},())
        rs.home = ccall((:getRUser,libR),Ptr{Cchar},())
        rs.ReadConsole = cglobal((:R_ReadConsole,libR),Void)
        rs.CallBack = pCallBack
        rs.ShowMessage = cglobal((:R_ShowMessage,libR),Void)
        rs.YesNoCancel = pYesNoCancel
        rs.Busy = cglobal((:R_Busy,libR),Void)
        rs.WriteConsoleEx = pWriteConsoleEx
        ccall((:R_SetParams,libR),Void,(Ptr{RStart},),&rs)
    else
        unsafe_store!(cglobal((:ptr_R_WriteConsoleEx,libR),Ptr{Void}), pWriteConsoleEx)
        unsafe_store!(cglobal((:R_Consolefile,libR),Ptr{Void}), C_NULL)
        unsafe_store!(cglobal((:R_Outputfile,libR),Ptr{Void}), C_NULL)
    end


    # IJulia hooks
    if isdefined(Main, :IJulia) && Main.IJulia.inited
        Main.IJulia.push_preexecute_hook(new_rplot)
        Main.IJulia.push_postexecute_hook(disp_rplot)
        Main.IJulia.push_posterror_hook(clean_rplot)

        global InlineDisplay = Main.IPythonDisplay.InlineDisplay
    end
end



end # module
