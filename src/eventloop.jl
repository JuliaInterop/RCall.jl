"""
    polled_events()::Cvoid

Event Callback: allows R to process Julia events when R is busy. For example, writing output to stdout while running an expensive R command.

See [Writing R Extensions: Calling R.dll directly](https://cran.r-project.org/doc/manuals/r-release/R-exts.html#Calling-R_002edll-directly)
and [Writing R Extensions: Meshing Event Loops](https://cran.r-project.org/doc/manuals/r-release/R-exts.html#Meshing-event-loops)
"""
function polled_events()::Cvoid
    # dump output buffer to stdout when available
    handle_eval_stdout()
    nothing
end

# there is no use now, maybe useful for the future.
function interrupts_pending(s::Bool=true)
    @static if Sys.iswindows()
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
        @static if Sys.iswindows() || Sys.isapple()
            ccall((:R_ProcessEvents, libR), Nothing, ())
        end
        @static if Sys.isunix()
            what = ccall((:R_checkActivity,libR),Ptr{Cvoid},(Cint,Cint),0,1)
            if what != C_NULL
                R_InputHandlers = unsafe_load(cglobal((:R_InputHandlers,libR),Ptr{Cvoid}))
                ccall((:R_runHandlers,libR),Nothing,(Ptr{Cvoid},Ptr{Cvoid}),R_InputHandlers,what)
            end
        end
    end
    nothing
end

global timeout = nothing

function rgui_start(silent=false)
    global timeout
    if timeout == nothing
        timeout = Base.Timer(x -> process_events(), 0.05, interval = 0.05)
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
    if  help_type == "html"
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
