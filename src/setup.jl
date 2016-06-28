if Compat.is_windows()
    import WinReg

    function locate_rhome()
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

    const Rhome = locate_rhome()
    const Ruser = homedir()
    const libR = Libdl.find_library(["R"],[joinpath(Rhome,"bin",Sys.WORD_SIZE==64?"x64":"i386")])

    function ask_yes_no_cancel(prompt::Ptr{Cchar})
        println(isdefined(Core, :String) ? String(prompt) : bytestring(prompt))
        query = readline(STDIN)
        c = uppercase(query[1])
        r::Cint
        r = (c=='Y' ? 1 : c=='N' ? -1 : 0)
        return r
    end

    """
        RStart

    This type mirrors `structRstart` in `R_ext/RStartup.h`. It is used to initialize the R engine.
    """
    type RStart # mirror structRstart in R_ext/RStartup.h
        R_Quiet::Cint
        R_Slave::Cint
        R_Interactive::Cint
        R_Verbose::Cint
        LoadSiteFile::Cint
        LoadInitFile::Cint
        DebugInitFile::Cint
        RestoreAction::Cint
        SaveAction::Cint
        vsize::Csize_t
        nsize::Csize_t
        max_vsize::Csize_t
        max_nsize::Csize_t
        ppsize::Csize_t
        NoRenviron::Cint
        rhome::Ptr{Cchar}
        home::Ptr{Cchar}
        ReadConsole::Ptr{Void}
        WriteConsole::Ptr{Void}
        CallBack::Ptr{Void}
        ShowMessage::Ptr{Void}
        YesNoCancel::Ptr{Void}
        Busy::Ptr{Void}
        CharacterMode::Cint
        WriteConsoleEx::Ptr{Void}
    end
    RStart() = RStart(0,0,0,0,0,
                      0,0,0,0,0,
                      0,0,0,0,0,
                      C_NULL,C_NULL,
                      C_NULL,C_NULL,C_NULL,C_NULL,
                      C_NULL,C_NULL,2,C_NULL)

end

if Compat.is_unix()
    function locate_rhome()
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

    const Rhome = locate_rhome()
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

    if Compat.is_windows()
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
        rs.CallBack       = cfunction(event_callback,Void,())
        rs.ShowMessage    = cglobal((:R_ShowMessage,libR),Void)
        rs.YesNoCancel    = cfunction(ask_yes_no_cancel,Cint,(Ptr{Cchar},))
        rs.Busy           = cglobal((:R_Busy,libR),Void)
        rs.WriteConsole   = C_NULL
        rs.WriteConsoleEx = cfunction(write_console_ex,Void,(Ptr{UInt8},Cint,Cint))

        ccall((:R_SetParams,libR),Void,(Ptr{RStart},),&rs)
    end

    if Compat.is_unix()
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

        ptr_write_console_ex = cfunction(write_console_ex,Void,(Ptr{UInt8},Cint,Cint))
        unsafe_store!(cglobal((:ptr_R_WriteConsole,libR),Ptr{Void}), C_NULL)
        unsafe_store!(cglobal((:ptr_R_WriteConsoleEx,libR),Ptr{Void}), ptr_write_console_ex)
        unsafe_store!(cglobal((:R_Consolefile,libR),Ptr{Void}), C_NULL)
        unsafe_store!(cglobal((:R_Outputfile,libR),Ptr{Void}), C_NULL)
        ptr_polled_events = cfunction(polled_events,Void,())
        unsafe_store!(cglobal((:R_PolledEvents,libR),Ptr{Void}), ptr_polled_events)
    end

    Rembedded[] = true
    atexit(endEmbeddedR)

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
    juliaCallback.p = makeNativeSymbolRef(cfunction(julia_extptr_callback,UnknownSxpPtr,(ListSxpPtr,)))
    juliaDecref[] = cfunction(decref_extptr,Void,(ExtPtrSxpPtr,))

    if !Rinited
        # print warnings as they arise
        # we can't use Rf_PrintWarnings as not exported on all platforms.
        rcall_p(:options,warn=1)

        # R gui eventloop
        isinteractive() && rgui_init()
        # R REPL mode
        isdefined(Base, :active_repl) && isinteractive() && repl_init(Base.active_repl)
    end

    # # IJulia hooks
    isdefined(Main, :IJulia) && Main.IJulia.inited && ijulia_init()
end
