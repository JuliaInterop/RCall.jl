# IJulia hooks for displaying plots with RCall

export rplot_set

const rplot_devno = Int32[1]
const rplot_file_base = joinpath(tempdir(),"IJulia_RCall")
const rplot_file_arg = rplot_file_base*"%03d"

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
    rcall(rplot_device(rplot_opts[1]),rplot_file_arg,rplot_opts[2]...;rplot_opts[3]...)
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
Closes graphics device and displays files in notebook.
"""->
function disp_rplot()
    d = rplot_devno[1]
    if d != 1
        rcall(symbol("dev.off"),d)
        rplot_devno[1] = rcopy(rcall(symbol("dev.cur")))[1]
        i = 1
        while true
            rplot_file = @sprintf "%s%03d" rplot_file_base i           
            if isfile(rplot_file)
                displayfile(rplot_opts[1],rplot_file)
                rm(rplot_file)
            else
                break
            end
            i += 1
        end
    end
end

# cleanup png device on error
function clean_rplot()
    d = rplot_devno[1]
    if d != 1
        rcall(symbol("dev.off"),d)
        rplot_devno[1] = rcopy(rcall(symbol("dev.cur")))[1]
    end
    i = 1
    while true
        rplot_file = @sprintf "%s%03d" rplot_file_base i           
        if isfile(rplot_file)
            rm(rplot_file)
        else
            break
        end
        i += 1
    end
end

