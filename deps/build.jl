using BinDeps

@BinDeps.setup

libR = library_dependency("libR")

rh = haskey(ENV,"R_HOME") ? ENV["R_HOME"] : (ENV["R_HOME"] = chomp(readall(`R RHOME`)))
libR = joinpath(rh,"lib",string("libR.",Base.Sys.shlib_ext))

@BinDeps.install [:libR => :libR]
