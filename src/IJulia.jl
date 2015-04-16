# IJulia hooks for displaying plots with RCall
import IPythonDisplay: InlineDisplay

export rplot_set

const rplot_devno = Int32[1]
const rplot_file = tempname()

const rplot_opts = Any[MIME"image/png"(),(480,400),()]

@doc """
Set options for R plotting with IJulia.

The first argument should be a MIME object: currently supported are 
* `MIME("image/png")` [default]
* `MIME("image/svg+xml")`

The remaining arguments are passed to the appropriate R graphics
device: see the relevant R help for details.
"""->
function rplot_set(m::MIME,args...;kwargs...)
    rplot_opts[1] = m
    rplot_opts[2] = args
    rplot_opts[3] = kwargs
    nothing
end
rplot_set(m::MIME"image/png") = rplot_set(m,480,400)
rplot_set(m::MIME"image/svg+xml") = rplot_set(m,6,5)

rplot_device(m::MIME"image/png") = :png
rplot_device(m::MIME"image/svg+xml") = :svg

@doc """
Called before cell evaluation. 
Opens new graphics device.
"""->
function new_rplot()
    rcall(rplot_device(rplot_opts[1]),rplot_file,rplot_opts[2]...;rplot_opts[3]...)
    rplot_devno[1] = rcopy(rcall(symbol("dev.cur")))[1]
end

function displayfile(m::MIME"image/png", f)
    open(f) do f
        d = readbytes(f)
        display(InlineDisplay(),m,d)
    end
end
function displayfile(m::MIME"image/svg+xml", f)
    open(f) do f
        d = readall(f)
        display(InlineDisplay(),m,d)
    end
end

@doc """
Called after cell evaluation.
Closes graphics device and displays file in notebook.
"""->
function disp_rplot()
    d = rplot_devno[1] 
    if d != 1
        rcall(symbol("dev.off"),d)
        rplot_devno[1] = rcopy(rcall(symbol("dev.cur")))[1]
        if isfile(rplot_file)
            displayfile(rplot_opts[1],rplot_file)
            rm(rplot_file)
        end
    end
end

# cleanup png device on error
function clean_rplot()
    d = rplot_devno[1] 
    if d != 1
        rprint("dev.list()")
        rcall(symbol("dev.off"),d)
        rplot_devno[1] = rcopy(rcall(symbol("dev.cur")))[1]
    end
    isfile(rplot_file) && rm(rplot_file)
end

Main.IJulia.push_preexecute_hook(new_rplot)
Main.IJulia.push_postexecute_hook(disp_rplot)
Main.IJulia.push_posterror_hook(clean_rplot)
