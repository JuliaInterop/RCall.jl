# IJulia hooks for displaying plots with RCall

if isdefined(Main, :IJulia) && Main.IJulia.inited
    import IPythonDisplay: InlineDisplay
    
    const pngfile = tempname()*".png"
    const ijulia_rplot_active = [false]
    const ijulia_rplot_dims = [480,360]

    # open new png device
    function new_rplot()
        rcall(:png,sexp(pngfile),sexp(ijulia_rplot_dims[1]),sexp(ijulia_rplot_dims[2]))
        ijulia_rplot_active[1] = true
    end

    # close and display png device
    function disp_rplot()
        if ijulia_rplot_active[1]
            rcall(symbol("dev.off"))
            ijulia_rplot_active[1] = false
            if isfile(pngfile)
                open(pngfile) do f
                    d = read(f,Uint8,filesize(pngfile))
                    display(InlineDisplay(),MIME("image/png"),d)
                end
                rm(pngfile)
            end
        end
    end
    
    # cleanup png device on error
    function clean_rplot()
        if ijulia_rplot_active[1]
            rcall(symbol("dev.off"))
            ijulia_rplot_active[1] = false
        end
        isfile(pngfile) && rm(pngfile)
    end
    
    Main.IJulia.push_preexecute_hook(new_rplot)
    Main.IJulia.push_postexecute_hook(disp_rplot)
    Main.IJulia.push_posterror_hook(clean_rplot)
end
