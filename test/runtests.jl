using Test
using Compat

hd = homedir()

if Compat.Sys.iswindows()
    Rhome = if haskey(ENV,"R_HOME")
        ENV["R_HOME"]
    else
        using WinReg
        WinReg.querykey(WinReg.HKEY_LOCAL_MACHINE, "Software\\R-Core\\R","InstallPath")
    end
    Rscript = joinpath(Rhome,"bin",Sys.WORD_SIZE==64 ? "x64" : "i386", "Rscript")
else
    Rscript = "Rscript"
end

libpaths = readlines(`$Rscript -e "writeLines(.libPaths())"`)

using RCall
using Nullables
using Missings

println(R"sessionInfo()")

println(R"l10n_info()")

# https://github.com/JuliaStats/RCall.jl/issues/68
@test hd == homedir()

# https://github.com/JuliaInterop/RCall.jl/issues/206
@test rcopy(Vector{String}, reval(".libPaths()")) == libpaths

tests = ["basic",
         "convert/base",
         "convert/missing",
         "convert/datetime",
         "convert/dataframe",
         "convert/categorical",
         "convert/formula",
         "convert/nullable",
         # "convert/axisarray", FIXME: AxisArrays is not yet fully compatible with v0.7
         "macros",
         "namespaces",
         "repl",
         ]

println("Running tests:")

for t in tests
    println(t)
    tfile = string(t, ".jl")
    include(tfile)
end

@test unsafe_load(cglobal((:R_PPStackTop, RCall.libR), Int)) == 0
