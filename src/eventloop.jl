function process_events()
    ##FIXME: a dirty fix to prevent segfault right after a sigint
    if unsafe_load(cglobal((:R_interrupts_pending,libR),Cint)) == 0
        if Sys.OS_NAME ∈ (:Darwin, :Windows)
            ccall((:R_ProcessEvents, libR), Void, ())
        end
        if Sys.OS_NAME != :Windows
            what = ccall((:R_checkActivity,libR),Ptr{Void},(Cint,Cint),0,1)
            if what != C_NULL
                R_InputHandlers = unsafe_load(cglobal((:R_InputHandlers,libR),Ptr{Void}))
                ccall((:R_runHandlers,libR),Void,(Ptr{Void},Ptr{Void}),R_InputHandlers,what)
            end
        end
    end
    nothing
end

global timeout = nothing

function rgui_start(silent=false)
    global timeout
    if timeout == nothing
        timeout = Base.Timer(x -> process_events(), 0.05, 0.05)
        return true
    else
        silent || error("eventloop is already running.")
        return false
    end
end

function rgui_stop(silent=false)
    global timeout
    if timeout != nothing
        close(timeout)
        timeout = nothing
        return true
    else
        silent || error("eventloop is not running.")
        return false
    end
end

function setHook(hookname, value)
    l = rparse("""setHook(hookname, function(...) foo)""")
    l[1][2] = hookname
    l[1][3][3] = value
    reval(l)
end

function rgui_init()
    f = rlang(rgui_start, true)
    setHook("plot.new", f)
    setHook("grid.newpage", f)
    setHook(rlang(:packageEvent, "rgl", "onLoad"), f)
end
