using RCall
using Test

using DataStructures: OrderedDict
using RCall: RClass

@testset "installation" begin
    include("installation.jl")
end

# before RCall does anything
const R_PPSTACKTOP_INITIAL = unsafe_load(cglobal((:R_PPStackTop, RCall.libR), Int))
@info "" R_PPSTACKTOP_INITIAL

hd = homedir()

if Sys.iswindows()
    Rhome = if haskey(ENV,"R_HOME")
        ENV["R_HOME"]
    else
        using WinReg
        WinReg.querykey(WinReg.HKEY_LOCAL_MACHINE, "Software\\R-Core\\R","InstallPath")
    end
    Rscript = joinpath(Rhome,"bin",Sys.WORD_SIZE==64 ? "x64" : "i386", "Rscript")
else
    Rscript = joinpath(RCall.Rhome, "bin", "Rscript")
end

libpaths = readlines(`$Rscript -e "writeLines(.libPaths())"`)

if VERSION ≤ v"1.1.1"
    using Missings
end
using Dates
import Base.VersionNumber

Rversion = VersionNumber(rcopy(R"as.character(getRversion())"))

println(R"sessionInfo()")

println(R"l10n_info()")

@testset "RCall" begin

    # https://github.com/JuliaStats/RCall.jl/issues/68
    @test hd == homedir()

    # https://github.com/JuliaInterop/RCall.jl/issues/206
    if (Sys.which("R") !== nothing) && (strip(read(`R RHOME`, String)) == RCall.Rhome)
        @test rcopy(Vector{String}, reval(".libPaths()")) == libpaths
    end

    tests = ["basic",
             "convert/base",
             "convert/missing",
             "convert/datetime",
             "convert/dataframe",
             "convert/categorical",
             "convert/formula",
             "convert/namedtuple",
             "convert/tuple",
             # "convert/axisarray",
             "macros",
             "namespaces",
             "repl",
             ]

    for t in tests
        @eval @testset $t begin
            include(string($t, ".jl"))
        end
    end

    @info "" RCall.conda_provided_r

    # make sure we're back where we started
    @test unsafe_load(cglobal((:R_PPStackTop, RCall.libR), Int)) == R_PPSTACKTOP_INITIAL
end
