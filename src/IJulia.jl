# IJulia hooks for displaying plots with RCall

if isdefined(Main, :IJulia) && Main.IJulia.inited
    import IPythonDisplay: InlineDisplay

    const rplot_active = Bool[false]
    const rplot_file = tempname()

    const rplot_opts = Any[MIME"image/png"(),(480,360),()]

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
    rplot_set(m::MIME"image/png") = rplot_set(m,480,360)
    rplot_set(m::MIME"image/svg+xml") = rplot_set(m,6,4)

    rplot_device(m::MIME"image/png") = :png
    rplot_device(m::MIME"image/svg+xml") = :svg


    # open new png device
    function new_rplot()
        rcall(rplot_device(rplot_opts[1]),rplot_file,rplot_opts[2]...;rplot_opts[3]...)
        rplot_active[1] = true
    end

    function displayfile(m::MIME"image/png", f)
        open(f) do f
            d = read(f,UInt8,filesize(rplot_file))
            display(InlineDisplay(),m,d)
        end
    end
    function displayfile(m::MIME"image/svg+xml", f)
        open(f) do f
            d = readall(f)
            display(InlineDisplay(),m,d)
        end
    end

    # close and display png device
    function disp_rplot()
        if rplot_active[1]
            rcall(symbol("dev.off"))
            rplot_active[1] = false
            if isfile(rplot_file)
                displayfile(rplot_opts[1],rplot_file)
                rm(rplot_file)
            end
        end
    end

    # cleanup png device on error
    function clean_rplot()
        if rplot_active[1]
            rcall(symbol("dev.off"))
            rplot_active[1] = false
        end
        isfile(rplot_file) && rm(rplot_file)
    end

    Main.IJulia.push_preexecute_hook(new_rplot)
    Main.IJulia.push_postexecute_hook(disp_rplot)
    Main.IJulia.push_posterror_hook(clean_rplot)
end
