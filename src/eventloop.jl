if Compat.Sys.isunix()
    "R eventloop hook on Unix system"
    function polled_events()
        event_callback()
        nothing
    end
end

"Event Callback: allows R to process Julia events when R is busy.
For example, writing output to STDOUT while running an expensive R command."
function event_callback()
    # dump printBuffer to STDOUT when available
    flush_output(STDOUT)
    nothing
end

# there is no use now, maybe useful for the future.
function interrupts_pending(s::Bool=true)
    if Compat.Sys.iswindows()
        unsafe_store!(cglobal((:UserBreak,libR),Cint), s ? 1 : 0)
    else
        unsafe_store!(cglobal((:R_interrupts_pending,libR),Cint), s ? 1 : 0)
    end
    nothing
end

# this shouldn't exist if we could hook into Julia eventloop.
function process_events()
    ##FIXME: a dirty fix to prevent segfault right after a sigint
    if unsafe_load(cglobal((:R_interrupts_pending,libR),Cint)) == 0
        if Compat.Sys.iswindows() || Compat.Sys.isapple()
            ccall((:R_ProcessEvents, libR), Void, ())
        end
        if Compat.Sys.isunix()
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

function set_hook(hookname, value)
    l = rparse("""setHook(hookname, function(...) foo)""")
    l[1][2] = hookname
    l[1][3][3] = value
    reval(l)
end

function rgui_init()
    f = rlang(rgui_start, true)
    set_hook("plot.new", f)
    set_hook("persp", f)
    set_hook("grid.newpage", f)
    set_hook(rlang(:packageEvent, "rgl", "onLoad"), f)

    # inject rgui_start(TRUE) to utils::help
    help_type = rcopy(rcall(:options, "help_type")[1])
    if  !isnull(help_type) && help_type == "html"
        # need to hack both as.environment('package:utils') and  getNamespace("utils")
        # to make ?foo and help("foo") to work
        l = rparse("help <- function(...) { foo(); bar(...) }")
        l[1][3][3][2] = f
        l[1][3][3][3][1] = reval("utils:::help")
        for env in (reval("as.environment('package:utils')"), getNamespace("utils"))
            rcall(:unlockBinding, "help", env)
            reval(l, env)
            rcall(:lockBinding, "help", env)
        end
    end
end
