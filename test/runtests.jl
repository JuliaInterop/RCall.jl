using Base.Test
hd = homedir()
pd = Pkg.dir()

if is_windows()
    Rhome = if haskey(ENV,"R_HOME")
        ENV["R_HOME"]
    else
        using WinReg
        WinReg.querykey(WinReg.HKEY_LOCAL_MACHINE, "Software\\R-Core\\R","InstallPath")
    end
    Rscript = joinpath(Rhome,"bin",Sys.WORD_SIZE==64?"x64":"i386","Rscript")
else
    Rscript = "Rscript"
end

libpaths = readlines(`$Rscript -e "writeLines(.libPaths())"`)
if VERSION < v"0.6.0"
    libpaths = map(chomp, libpaths)
end


using RCall
using Compat

# https://github.com/JuliaStats/RCall.jl/issues/68
@test hd == homedir()
@test pd == Pkg.dir()

# https://github.com/JuliaInterop/RCall.jl/issues/206
@test rcopy(Vector{String}, reval(".libPaths()")) == libpaths

tests = ["basic",
         "convert/base",
         "convert/dataframe",
         # "convert/datatable",
         "convert/datetime",
         "convert/axisarray",
         "convert/namedarray",
         "render",
         "namespaces",
         "repl",
         ]

println("Running tests:")

for t in tests
    tfile = string(t, ".jl")
    println(" * $(tfile) ...")
    include(tfile)
end
