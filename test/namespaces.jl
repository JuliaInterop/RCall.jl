# library
# Since @rimport and @rlibrary create module objects which may be conflict with other objects,
# it is safer to place them at the end of the tests.

module NamespaceTests
    using RCall
    using Test

    reval("""has_mass_package = require("MASS")""")

    RCall.@rget has_mass_package

    @info "" has_mass_package

    if has_mass_package # these tests will fail if the R "MASS" package is not already installed
        @rimport MASS
        @test rcopy(rcall(MASS.ginv, RObject([1 2; 0 4]))) ≈ [1 -0.5; 0 0.25]
        @rimport MASS as mass
        @test rcopy(rcall(mass.ginv, RObject([1 2; 0 4]))) ≈ [1 -0.5; 0 0.25]
        @rlibrary MASS
        @test rcopy(rcall(ginv, RObject([1 2; 0 4]))) ≈ [1 -0.5; 0 0.25]
    end

    # get these to install correctly in CI with a source build is a pain
    # so we only do it on platforms where a binary build is available
    if !rcopy(reval("""require("ape")""")) && (Sys.iswindows() || Sys.isapple()) # 418
        @info "installing ape to temporary lib"
        tmp, _ = mktemp()
        reval(""".libPaths("$(tmp)")
                 lib <- .libPaths()[1L]
                 install.packages("ape", repos="https://cloud.r-project.org", lib=lib, type="binary")
                 library("ape")""")
    end

    @test_throws ErrorException rimport("ape")

    rimport(:ape; normalization=["." => "__"])
    # stats is always available
    rimport(:stats; normalizenames=false)
end
