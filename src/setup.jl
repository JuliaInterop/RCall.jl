@windows_only begin
    import WinReg
    
    function locate_Rhome()
        if haskey(ENV,"R_HOME")
            Rhome = ENV["R_HOME"]
        else
            Rhome = WinReg.querykey(WinReg.HKEY_LOCAL_MACHINE, "Software\\R-Core\\R","InstallPath")
        end
        
        if isdir(Rhome)
            println("R installation found at \"$Rhome\"")
            return Rhome
        end
        error("Could not locate R installation. Try setting \"R_HOME\" environmental variable.")        
    end
    
    const Rhome = locate_Rhome()
    const Ruser = homedir()
    const libR = Libdl.find_library(["R"],[joinpath(Rhome,"bin",WORD_SIZE==64?"x64":"i386")])
end

@unix_only begin
    function locate_Rhome()
        if haskey(ENV,"R_HOME")
            Rhome = ENV["R_HOME"]
        else
            Rhome = readchomp(`R RHOME`)
        end
        if isdir(Rhome)
            println("R installation found at \"$Rhome\"")
            return Rhome
        end
        error("Could not find R installation. Try setting \"R_HOME\" environmental variable.")
    end

    const Rhome = locate_Rhome()
    const libR  = Libdl.find_library(["libR"],[joinpath(Rhome,"lib")])
end

const Rembedded = Ref{Bool}(false)


"""
    initEmbeddedR()

This initializes an embedded R session. It should only be called when R is not already running (e.g. if Julia is running inside an R session)
"""
function initEmbeddedR()

    # disable R signal handling
    unsafe_store!(cglobal((:R_SignalHandlers,RCall.libR),Cint),0)

    @windows_only begin
        # TODO: Use direct Windows interface, see §8.2.2 "Calling R.dll directly"
        # of "Writing R Extensions" (aka R-exts)
        
        ccall(:_wputenv,Cint,(Cwstring,),"PATH="*ENV["PATH"]*";"*dirname(libR))
        ccall(:_wputenv,Cint,(Cwstring,),"HOME="*homedir())

        argv = ["REmbeddedJulia","--silent","--no-save"]
        i = ccall((:Rf_initEmbeddedR,libR),Cint,(Cint,Ptr{Ptr{Cchar}}),length(argv),argv)
        if i == 0
            error("Could not start embedded R session.")
        end

        rs = RStart()
        ccall((:R_DefParams,libR),Void,(Ptr{RStart},),&rs)

        rs.rhome          = ccall((:get_R_HOME,libR),Ptr{Cchar},())
        rs.home           = ccall((:getRUser,libR),Ptr{Cchar},())
        rs.ReadConsole    = cglobal((:R_ReadConsole,libR), Void)
        rs.CallBack       = cfunction(eventCallBack,Void,())
        rs.ShowMessage    = cglobal((:R_ShowMessage,libR),Void)
        rs.YesNoCancel    = cfunction(askYesNoCancel,Cint,(Ptr{Cchar},))
        rs.Busy           = cglobal((:R_Busy,libR),Void)
        rs.WriteConsole   = C_NULL
        rs.WriteConsoleEx = cfunction(writeConsoleEx,Void,(Ptr{UInt8},Cint,Cint))
        
        ccall((:R_SetParams,libR),Void,(Ptr{RStart},),&rs)
    end

    @unix_only begin
        # set necessary environmental variables
        ENV["R_HOME"] = Rhome
        ENV["R_DOC_DIR"] = joinpath(Rhome,"doc")
        ENV["R_INCLUDE_DIR"] = joinpath(Rhome,"include")
        ENV["R_SHARE_DIR"] = joinpath(Rhome,"share")


        # initialize library
        argv = ["REmbeddedJulia","--silent","--no-save"]
        i = ccall((:Rf_initEmbeddedR,libR),Cint,(Cint,Ptr{Ptr{Cchar}}),length(argv),argv)
        if i == 0
            error("Could not start embedded R session.")
        end

        pWriteConsoleEx = cfunction(writeConsoleEx,Void,(Ptr{UInt8},Cint,Cint))
        unsafe_store!(cglobal((:ptr_R_WriteConsole,libR),Ptr{Void}), C_NULL)
        unsafe_store!(cglobal((:ptr_R_WriteConsoleEx,libR),Ptr{Void}), pWriteConsoleEx)
        unsafe_store!(cglobal((:R_Consolefile,libR),Ptr{Void}), C_NULL)
        unsafe_store!(cglobal((:R_Outputfile,libR),Ptr{Void}), C_NULL)

    end

    Rembedded[] = true
    atexit(endEmbeddedR)

end

function __init__()
    # Check if R already running
    Rinited = unsafe_load(cglobal((:R_NilValue,libR),Ptr{Void})) != C_NULL
    
    if !Rinited
        initEmbeddedR()
    end

    ip = ccall((:Rf_ScalarInteger,libR),Ptr{Void},(Cint,),0)
    voffset[] = ccall((:INTEGER,libR),Ptr{Void},(Ptr{Void},),ip) - ip

    Const.load()

    # set up function callbacks
    juliaCallback.p = makeNativeSymbol(cfunction(callJuliaExtPtr,UnknownSxpPtr,(ListSxpPtr,)))
    juliaDecref[] = cfunction(decrefExtPtr,Void,(ExtPtrSxpPtr,))

    if !Rinited
        # print warnings as they arise
        # we can't use Rf_PrintWarnings as not exported on all platforms.
        rcall_p(:options,warn=1)

        # R gui eventloop
        isinteractive() && rgui_init()
    end

    # # IJulia hooks
    isdefined(Main, :IJulia) && Main.IJulia.inited && ijulia_init()
end



"""
    endEmbeddedR()

Close embedded R session.
"""
function endEmbeddedR()
    if Rembedded[]
        ccall((:Rf_endEmbeddedR,libR),Void,(Cint,),0)
        Rembedded[] = false
    end
end
