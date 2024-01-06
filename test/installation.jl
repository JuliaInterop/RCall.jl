# This file is used to test installation of the RCall package. We run
# a new Julia process in a temporary environment so that we
# can test what happens without already having imported RCall.

using Test

const RCALL_DIR = dirname(@__DIR__)

function test_installation(file, project=mktempdir())
    path = joinpath(@__DIR__, "installation", file)
    cmd = `$(Base.julia_cmd()) --project=$(project) $(path)`
    return @test success(Cmd(cmd; env=Dict("RCALL_DIR" => RCALL_DIR)))
end

mktempdir() do dir
  @testset "No R" begin
      test_installation("rcall_without_r.jl", dir)
  end
  @testset "Preferences" begin
    test_installation("swap_to_prefs_and_condapkg.jl", dir)
  end
end

# We want to guard this with a version check so we don't run into the following
# (non-widespread) issue on older versions of Julia:
# https://github.com/JuliaLang/julia/issues/34276
# (related to incompatible libstdc++ versions)
@static if VERSION ≥ v"1.9"
  # Test whether we can install RCall with Conda, and then switch to using
  # Preferences + CondaPkg
  mktempdir() do dir
      @testset "Conda" begin
          test_installation("install_conda.jl", dir)
      end
      @testset "Conda 2 Preferences" begin
          test_installation("swap_to_prefs_and_condapkg.jl", dir)
      end
      @testset "Back 2 Conda" begin
          test_installation("drop_preferences.jl", dir)
      end
  end
end
