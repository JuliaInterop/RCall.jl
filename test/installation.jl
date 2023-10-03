"""
This file is used to test installation of the RCall package. We rerun this
script in a new Julia process to get a clean environment without RCall so we
can test what happens without already having imported RCall. Tasks for the
Julia subprocess are passed using the SUBINTERPRETER_TASK environment
variable.
"""

using Base.Filesystem: mktempdir
import Pkg

rcall_dir = (@__DIR__) * "/../"


function mk_temp_proj()
  temp_proj = mktempdir()
  Pkg.activate(temp_proj)
  Pkg.add("Pkg")
  Pkg.activate()
  return temp_proj
end

function restart_in_proj(proj, args...)
  julia_cmd = Base.julia_cmd()
  cmd = `$(julia_cmd) --project=$(proj) $(@__FILE__) $(join(args, " "))`
  return Base.run(cmd)
end

function with_subinterpreter_task(func, task)
  ENV["SUBINTERPRETER_TASK"] = task
  func()
  delete!(ENV, "SUBINTERPRETER_TASK")
end

subinterpreter_task = get(ENV, "SUBINTERPRETER_TASK", "")

# This is just to stop errors due to @test not being defined when we run in
# another project
@static if !(@isdefined Test)
  macro test(ex)
    ex
  end
end

if subinterpreter_task == "can_install_rcall_without_r"
  ENV["R_HOME"] = "_"
  Pkg.add(path=rcall_dir)
  Pkg.build()
  try
    Base.require(Main, :RCall)
  catch e
    if !(e isa LoadError)
      println(stderr, "Expected LoadError when running RCall but got $e")
      exit(1)
    end
    exit(0)
  end
  println(stderr, "RCall unexpectedly loaded")
  exit(1)
elseif subinterpreter_task == "can_install_conda"
  ENV["R_HOME"] = "*"
  Pkg.add(path=rcall_dir)
  Pkg.build("RCall")
  rcall = Base.require(Main, :RCall)
  if occursin(r"/conda/3/([^/]+/)?lib/R", rcall.Rhome)
    exit(0)
  end
  println(stderr, "Wrong Conda Rhome $(rcall.Rhome)")
  exit(1)
elseif subinterpreter_task == "get_localpreference_toml"
  CondaPkg = Base.require(Main, :CondaPkg)
  Libdl = Base.require(Main, :Libdl)
  function locate_libR(Rhome)
      @static if Sys.iswindows()
          libR = joinpath(Rhome, "bin", Sys.WORD_SIZE==64 ? "x64" : "i386", "R.dll")
      else
          libR = joinpath(Rhome, "lib", "libR.$(Libdl.dlext)")
      end
      return libR
  end
  condapkg_toml = joinpath(ARGS[1], "CondaPkg.toml")
  open(condapkg_toml, "w") do io
    write(
      io,
      """
      [deps]
      r = ""
      """
    )
  end
  CondaPkg.resolve()
  target_rhome = "$(CondaPkg.envdir())/lib/R"
  localpreference_toml = joinpath(ARGS[1], "LocalPreferences.toml")
  open(localpreference_toml, "w") do io
    write(
      io,
      """
      [RCall]
      Rhome = "$target_rhome"
      libR = "$(locate_libR(target_rhome))"
      """
    )
  end
  exit(0)
elseif subinterpreter_task == "can_switch_to_condapkg"
  rcall = Base.require(Main, :RCall)
  if occursin("/.CondaPkg/env/lib/R", rcall.Rhome)
    exit(0)
  end
  println(stderr, "Wrong RCall used $(rcall.Rhome)")
  exit(1)
end

@assert subinterpreter_task == ""

# Test whether we can install RCall without R
rcall_without_r_proj = mk_temp_proj()
with_subinterpreter_task("can_install_rcall_without_r") do
  process = restart_in_proj(rcall_without_r_proj)
  @test process.exitcode == 0
end

# We want to guard this with a version check so we don't run into the following
# (non-widespread) issue on older versions of Julia:
# https://github.com/JuliaLang/julia/issues/34276
@static if VERSION ≥ v"1.9"
  # Test whether we can install RCall with Conda, and then switch to using
  # Preferences + CondaPkg
  conda_then_condapkg_proj = mk_temp_proj()
  with_subinterpreter_task("can_install_conda") do
    process = restart_in_proj(conda_then_condapkg_proj)
    @test process.exitcode == 0
  end

  Pkg.activate(conda_then_condapkg_proj)
  Pkg.add("CondaPkg")
  Pkg.add("Libdl")
  Pkg.activate()
  with_subinterpreter_task("get_localpreference_toml") do
    process = restart_in_proj(conda_then_condapkg_proj, conda_then_condapkg_proj)
    @test process.exitcode == 0
  end

  with_subinterpreter_task("can_switch_to_condapkg") do
    process = restart_in_proj(conda_then_condapkg_proj)
    @test process.exitcode == 0
  end
end
