using Libdl

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
        Base.with_output_color(:red, stderr) do io
            print(io, "ERROR: ")
            showerror(io, er)
            println(io)
        end
        @static if Sys.iswindows()
            error("Try adding $(dirname(libR)) to the \"PATH\" environmental variable and restarting Julia.")
        else
            error("Try adding $(dirname(libR)) to the \"LD_LIBRARY_PATH\" environmental variable and restarting Julia.")
        end
    end
    # R_tryCatchError is only available on v3.4.0 or later.
    if Libdl.dlsym_e(libptr, "R_tryCatchError") == C_NULL
        error("R library $libR appears to be too old. RCall.jl requires R 3.4.0 or later.")
    end
    Libdl.dlclose(libptr)
    return true
end

function locate_libR(Rhome)
    @static if Sys.iswindows()
        libR = joinpath(Rhome, "bin", Sys.WORD_SIZE==64 ? "x64" : "i386", "R.dll")
    else
        libR = joinpath(Rhome, "lib", "libR.$(Libdl.dlext)")
    end
    validate_libR(libR)
    return libR
end
