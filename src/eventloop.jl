function process_events()
    ##FIXME: a dirty fix to prevent segfault right after a sigint
    unsafe_store!(cglobal((:R_interrupts_pending,libR),Cint),0)

    if Sys.OS_NAME == :Darwin
        ccall((:R_ProcessEvents, libR), Void, ())
    end
    what = ccall((:R_checkActivity,libR),Ptr{Void},(Cint,Cint),0,1)
    if what != C_NULL
        R_InputHandlers = unsafe_load(cglobal((:R_InputHandlers,libR),Ptr{Void}))
        ccall((:R_runHandlers,libR),Void,(Ptr{Void},Ptr{Void}),R_InputHandlers,what)
    end
    nothing
end

global timeout = nothing

function rgui_start()
    global timeout
    if timeout == nothing
        timeout = Base.Timer(x -> process_events(), 0.05, 0.05)
    else
        error("eventloop is running.")
    end
    nothing
end

function rgui_stop()
    global timeout
    if timeout != nothing
        close(timeout)
        timeout = nothing
    else
        error("eventloop is not running.")
    end
    nothing
end
