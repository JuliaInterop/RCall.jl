# This file is used to test installation of the RCall package. We run
# a new Julia process in a temporary environment so that we
# can test what happens without already having imported RCall.

using Test

const RCALL_DIR = dirname(@__DIR__)

function test_installation(file, project=mktempdir())
    path = joinpath(@__DIR__, "installation", file)
    @static if Sys.isunix()
        # this weird stub is necessary so that all the nested conda installation processes
        # have access to the PATH
        cmd = `sh -c $(Base.julia_cmd()) --project=$(project) $(path)`
    elseif Sys.iswindows()
        cmd = `cmd /C $(Base.julia_cmd()) --project=$(project) $(path)`
    else
        error("What system are you on?!")
    end
    cmd = Cmd(cmd; env=Dict("RCALL_DIR" => RCALL_DIR))
    @test mktemp() do file, io
        try
            result = run(pipeline(cmd; stdout=io, stderr=io))
            return success(result)
        catch
            @error open(f -> read(f, String), file)
            return false
        end
    end
end

mktempdir() do dir
    @testset "No R" begin
        test_installation("rcall_without_r.jl", dir)
    end
    # We want to guard this with a version check so we don't run into the following
    # (non-widespread) issue on older versions of Julia:
    # https://github.com/JuliaLang/julia/issues/34276
    # (related to incompatible libstdc++ versions)
    @static if VERSION ≥ v"1.9"
        @testset "Preferences" begin
            test_installation("swap_to_prefs_and_condapkg.jl", dir)
        end
    end
end

# We want to guard this with a version check so we don't run into the following
# issue on older versions of Julia:
# https://github.com/JuliaLang/julia/issues/34276
# (related to incompatible libstdc++ versions)
@static if VERSION ≥ v"1.9"
    # Test whether we can install RCall with Conda, and then switch to using
    # Preferences + CondaPkg
    mktempdir() do dir
        # we run into weird issues with this on CI
        @static if Sys.isunix()
            @testset "Conda" begin
                test_installation("install_conda.jl", dir)
            end
        end
        @testset "Swap to Preferences" begin
            test_installation("swap_to_prefs_and_condapkg.jl", dir)
        end
        @static if Sys.isunix()
            @testset "Swap back from Preferences" begin
                test_installation("drop_preferences.jl", dir)
            end
        end
    end
end
