# IJulia hooks for displaying plots with RCall

# TODO: create a special graphics device. 
# This would allow us to not accidentally close devices opened by users, 
# and display plots immediately as they appear.

const IJULIA_MIME = Ref{Union{Nothing,MIME}}(nothing)
const IJULIA_FILE_DIR = Ref{String}("")

"""
    ijulia_setdevice(m::MIME; kwargs...)
    ijulia_setdevice(m::MIME"image/png"; width=6*72, height=5*72)
    ijulia_setdevice(m::MIME"image/svg+xml"; width=6, height=5)

Set options for R plotting with IJulia.

The first argument should be a MIME object: currently supported are
* `MIME("image/png")` [default]
* `MIME("image/svg+xml")`

The keyword arguments are forwarded to the appropriate R graphics
device: see the relevant R help for details.
"""
function ijulia_setdevice(m::MIME; kwargs...)
    rcall_p(:options; rcalljl_device=rdevicename(m))
    rcall_p(:options; rcalljl_options=Dict(kwargs))
    IJULIA_MIME[] = m
    return nothing
end
ijulia_setdevice(m::MIME"image/png") = ijulia_setdevice(m; width=6*72, height=5*72)
ijulia_setdevice(m::MIME"image/svg+xml") = ijulia_setdevice(m; width=6, height=5)

"""
    rdevicename(::MIME"image/png")
    rdevicename(::MIME"image/svg+xml")

Return the name of the associated R device as a symbol.

See also [`ijulia_setdevice`](@ref).
"""
rdevicename(::MIME"image/png") = :png
rdevicename(::MIME"image/svg+xml") = :svg
rdevicename(m::MIME) = throw(ArgumentError(string("Unsupported MIME type: ", m)))

"""
    ijulia_displayfile(m::MIME, f)

Display a graphics file in IJulia.

This function generally should not be called by the user, but instead by 
the appropriate display hook.

See also [`ijulia_setdevice`](@ref).
"""
function ijulia_displayfile(m::MIME"image/png", f)
    open(f) do f
        d = read(f)
        display(m, d)
    end
end

function ijulia_displayfile(m::MIME"image/svg+xml", f)
    # R svg images use named defs, which cause problem when used inline, see
    # https://github.com/jupyter/notebook/issues/333
    # we get around this by renaming the elements.
    open(f) do f
        r = randstring()
        d = read(f, String)
        d = replace(d, "id=\"glyph" => "id=\"glyph" * r)
        d = replace(d, "href=\"#glyph" => "href=\"#glyph" * r)
        display(m, d)
    end
end

"""
    ijulia_displayplots()

Closes graphics device and displays files in notebook.

This is a postexecution hook called by IJulia after cell evaluation
and should generally not be called by the user.
"""
function ijulia_displayplots()
    if rcopy(Int,rcall_p(Symbol("dev.cur"))) != 1
        rcall_p(Symbol("dev.off"))
        for fn in sort(readdir(IJULIA_FILE_DIR[]))
            ffn = joinpath(IJULIA_FILE_DIR[],fn)
            ijulia_displayfile(IJULIA_MIME[],ffn)
            rm(ffn)
        end
    end
end

"""
    ijulia_cleanup()

Clean up R display device and temporary files after error.
"""
function ijulia_cleanup()
    if rcopy(Int, rcall_p(Symbol("dev.cur"))) != 1
        rcall_p(Symbol("dev.off"))
    end
    for fn in readdir(IJULIA_FILE_DIR[])
        ffn = joinpath(IJULIA_FILE_DIR[], fn)
        rm(ffn)
    end
end

"""
    ijulia_init()

Initialize RCall's IJulia support.
"""
function ijulia_init()
    # TODO: use scratchspace?
    IJULIA_FILE_DIR[] = mktempdir()
    ijulia_file_fmt = joinpath(IJULIA_FILE_DIR[],"rij_%03d")
    rcall_p(:options; rcalljl_filename=ijulia_file_fmt)

    reval_p(rparse_p("""
        options(device = function(filename=getOption('rcalljl_filename'), ...) {
            args <- c(filename = filename, getOption('rcalljl_options'))
            do.call(getOption('rcalljl_device'), modifyList(args, list(...)))
        })
        """))

    # TODO: remove the implicit dependency on IJulia
    # and be explicit via package extensions
    Main.IJulia.push_postexecute_hook(ijulia_displayplots)
    Main.IJulia.push_posterror_hook(ijulia_cleanup)
    ijulia_setdevice(MIME"image/png"())
end
