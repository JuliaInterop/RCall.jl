# These are tests making sure that we don't change the system configuration during our build and configuration process.
if Sys.iswindows()
    Rhome = if haskey(ENV,"R_HOME")
        ENV["R_HOME"]
    else
        using WinReg
        WinReg.querykey(WinReg.HKEY_LOCAL_MACHINE, "Software\\R-Core\\R","InstallPath")
    end
    const Rscript = joinpath(Rhome,"bin",Sys.WORD_SIZE==64 ? "x64" : "i386", "Rscript")
else
    const Rscript = joinpath(RCall.Rhome, "bin", "Rscript")
end

const R_LIBPATHS = readlines(`$Rscript -e "writeLines(.libPaths())"`)

# https://github.com/JuliaStats/RCall.jl/issues/68
@test HOMEDIR_AT_STARTUP == homedir()

# https://github.com/JuliaInterop/RCall.jl/issues/206
if (Sys.which("R") !== nothing) && (strip(read(`R RHOME`, String)) == RCall.Rhome)
    @test rcopy(Vector{String}, reval(".libPaths()")) == R_LIBPATHS
end

@info (R"sessionInfo()")
@info (R"l10n_info()")
@info "" RCall.conda_provided_r
