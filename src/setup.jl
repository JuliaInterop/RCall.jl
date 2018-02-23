@static if Compat.Sys.iswindows()
    import WinReg

    function ask_yes_no_cancel(prompt::Ptr{Cchar})
        println(String(prompt))
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
    mutable struct RStart # mirror structRstart in R_ext/RStartup.h
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

const Rembedded = Ref{Bool}(false)
const voffset = Ref{UInt}()

"""
    validate_libR(libR)

Checks that the R library `libR` can be loaded and is satisfies version requirements.
"""
function validate_libR(libR)
    if !isfile(libR)
        error("Could not find library $libR. Make sure that R shared library exists.")
    end
    # Issue #143
    # On linux, sometimes libraries linked from libR (e.g. libRblas.so) won't open unless LD_LIBRARY_PATH is set correctly.
    libptr = try
        Libdl.dlopen(libR)
    catch er
        Base.with_output_color(:red, STDERR) do io
            print(io, "ERROR: ")
            showerror(io, er)
            println(io)
        end
        if Compat.Sys.iswindows()
            error("Try adding $(dirname(libR)) to the \"PATH\" environmental variable and restarting Julia.")
        else
            error("Try adding $(dirname(libR)) to the \"LD_LIBRARY_PATH\" environmental variable and restarting Julia.")
        end
    end
    # R_tryCatchError is only available on v3.4.0 or later.
    if Libdl.dlsym_e(libptr, "R_tryCatchError") == C_NULL
        error("R library $libR appears to be too old. RCall.jl requires R 3.4.0 or later")
    end
    Libdl.dlclose(libptr)
end

"""
    initEmbeddedR()

This initializes an embedded R session. It should only be called when R is not already running (e.g. if Julia is running inside an R session)
"""
function initEmbeddedR()

    # disable R signal handling
    unsafe_store!(cglobal((:R_SignalHandlers,RCall.libR),Cint),0)

    @static if Compat.Sys.iswindows()
        # TODO: Use direct Windows interface, see §8.2.2 "Calling R.dll directly"
        # of "Writing R Extensions" (aka R-exts)

        Ruser_ptr = ccall((:getRUser,libR),Ptr{Cchar},())
        Ruser = unsafe_string(Ruser_ptr)

        ccall(:_wputenv,Cint,(Cwstring,),"PATH="*ENV["PATH"]*";"*dirname(libR))
        ccall(:_wputenv,Cint,(Cwstring,),"R_USER="*Ruser)

        # otherwise R will set it itself, which can be wrong on Windows
        if !("HOME" in keys(ENV))
            ccall(:_wputenv,Cint,(Cwstring,),"HOME="*homedir())
        end

        argv = ["REmbeddedJulia","--silent","--no-save"]
        i = ccall((:Rf_initEmbeddedR,libR),Cint,(Cint,Ptr{Ptr{Cchar}}),length(argv),argv)
        if i == 0
            error("Could not start embedded R session.")
        end

        rs = RStart()
        ccall((:R_DefParams,libR),Void,(Ptr{RStart},),&rs)

        rs.rhome          = ccall((:get_R_HOME,libR),Ptr{Cchar},())
        rs.home           = Ruser_ptr
        rs.ReadConsole    = cglobal((:R_ReadConsole,libR), Void)
        rs.CallBack       = cfunction(event_callback,Void,())
        rs.ShowMessage    = cglobal((:R_ShowMessage,libR),Void)
        rs.YesNoCancel    = cfunction(ask_yes_no_cancel,Cint,(Ptr{Cchar},))
        rs.Busy           = cglobal((:R_Busy,libR),Void)
        rs.WriteConsole   = C_NULL
        rs.WriteConsoleEx = cfunction(write_console_ex,Void,(Ptr{UInt8},Cint,Cint))

        ccall((:R_SetParams,libR),Void,(Ptr{RStart},),&rs)
    end

    @static if Compat.Sys.isunix()
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
        ccall((:Rf_endEmbeddedR, libR),Void,(Cint,),0)
        Rembedded[] = false
    end
end

const depfile = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
include(depfile)

function __init__()
    validate_libR(libR)

    # Check if R already running
    Rinited = unsafe_load(cglobal((:R_NilValue, libR),Ptr{Void})) != C_NULL

    if !Rinited
        initEmbeddedR()
    end

    ip = ccall((:Rf_ScalarInteger, libR),Ptr{Void},(Cint,),0)
    voffset[] = ccall((:INTEGER, libR),Ptr{Void},(Ptr{Void},),ip) - ip

    Const.load()

    # set up function callbacks
    setup_callbacks()

    if !Rinited
        # print warnings as they arise
        # we can't use Rf_PrintWarnings as not exported on all platforms.
        rcall_p(:options,warn=1)

        # R gui eventloop
        isinteractive() && rgui_init()
    end

    # R REPL mode
    isdefined(Base, :active_repl) &&
        isinteractive() && typeof(Base.active_repl) != Base.REPL.BasicREPL &&
            !RPrompt.repl_inited(Base.active_repl) && RPrompt.repl_init(Base.active_repl)

    # # IJulia hooks
    isdefined(Main, :IJulia) && Main.IJulia.inited && ijulia_init()
end
