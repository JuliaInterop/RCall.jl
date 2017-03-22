"""
    validate_libR(libR)

Checks that the R library `libR` can be loaded and is satisfies version requirements.
Returns `true` if valid, throws an error if not.
"""
function validate_libR(libR)
    # Issue #143
    # On linux, sometimes libraries linked from libR (e.g. libRblas.so) won't open unless LD_LIBRARY_PATH is set correctly.
    libptr = Libdl.dlopen_e(libR)
    if libptr == C_NULL
        if is_windows()
            error("Could not load library $libR. Try adding $(dirname(libR)) to the \"PATH\" environmental variable and restarting Julia.")
        else
            error("Could not load library $libR. Try adding $(dirname(libR)) to the \"LD_LIBRARY_PATH\" environmental variable and restarting Julia.")
        end
    end
    # Issue #74
    # R_BlankScalarString is only available on v3.2.0 or later.
    if Libdl.dlsym_e(libptr,"R_BlankScalarString") == C_NULL
        error("R libary $libR appears to be too old. RCall.jl requires R 3.2.0 or later")
    end
    Libdl.dlclose(libptr)
    return true
end


@static if is_windows()
    import WinReg

    function locate_Rhome_libR()
        Rhome = if haskey(ENV,"R_HOME")
            ENV["R_HOME"]
        else
            try
                WinReg.querykey(WinReg.HKEY_LOCAL_MACHINE, "Software\\R-Core\\R","InstallPath")
            catch e
                ""
            end
        end

        libR = Libdl.find_library(["R"],[joinpath(Rhome,"bin",Sys.WORD_SIZE==64?"x64":"i386")])

        if isdir(Rhome) && validate_libR(libR)
            info("Using R installation at $Rhome")
            return Rhome, libR
        end
        error("Could not locate R installation. Try setting \"R_HOME\" environmental variable.")
    end

    const Rhome, libR = locate_Rhome_libR()
    const Ruser = homedir()


    function ask_yes_no_cancel(prompt::Ptr{Cchar})
        println(isdefined(Core, :String) ? String(prompt) : bytestring(prompt))
        query = readline(STDIN)
        c = uppercase(query[1])
        local r::Cint
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

@static if is_unix()
    function locate_Rhome_libR()
        Rhome = if haskey(ENV,"R_HOME")
            ENV["R_HOME"]
        else
            try
                readchomp(`R RHOME`)
            catch e
                ""
            end
        end
        libR = joinpath(Rhome,"lib","libR.$(Libdl.dlext)")
        if isdir(Rhome) && isfile(libR) && validate_libR(libR)
            info("Using R installation at $Rhome")
            return Rhome, libR
        end
        error("Could not find R installation. Either set the \"R_HOME\" environmental variable, or ensure the R executable is available in \"PATH\".")
    end

    const Rhome, libR = locate_Rhome_libR()
end

const Rembedded = Ref{Bool}(false)


"""
    initEmbeddedR()

This initializes an embedded R session. It should only be called when R is not already running (e.g. if Julia is running inside an R session)
"""
function initEmbeddedR()

    # disable R signal handling
    unsafe_store!(cglobal((:R_SignalHandlers,RCall.libR),Cint),0)

    @static if is_windows()
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

    @static if is_unix()
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
    validate_libR(libR)

    # Check if R already running
    Rinited = unsafe_load(cglobal((:R_NilValue,libR),Ptr{Void})) != C_NULL

    if !Rinited
        initEmbeddedR()
    end

    ip = ccall((:Rf_ScalarInteger,libR),Ptr{Void},(Cint,),0)
    voffset[] = ccall((:INTEGER,libR),Ptr{Void},(Ptr{Void},),ip) - ip

    Const.load()

    # set up function callbacks
    juliaCallback.p = makeNativeSymbolRef(cfunction(julia_extptr_callback,Ptr{UnknownSxp},(Ptr{ListSxp},)))
    juliaDecref[] = cfunction(decref_extptr,Void,(Ptr{ExtPtrSxp},))

    if !Rinited
        # print warnings as they arise
        # we can't use Rf_PrintWarnings as not exported on all platforms.
        rcall_p(:options,warn=1)

        # R gui eventloop
        isinteractive() && rgui_init()
        # R REPL mode
        isdefined(Base, :active_repl) && isinteractive() && typeof(Base.active_repl) != Base.REPL.BasicREPL && repl_init(Base.active_repl)
    end

    # # IJulia hooks
    isdefined(Main, :IJulia) && Main.IJulia.inited && ijulia_init()
end
