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

    # why exclude Windows? because the tempdir could potentially include
    # unicode characters and R can't handle that
    if !Sys.iswindows()
        if !rcopy(reval("""require("ape")"""))  # 418
            @info "installing ape to temporary lib"
            tmp = mktempdir()
            reval("""lib <- "$(tmp)"
                     .libPaths(lib)
                     install.packages("ape", repos="https://cloud.r-project.org", method="wget", lib=lib)
                     library("ape")""")
        end

        @test_throws ErrorException rimport("ape")

        rimport(:ape; normalization=["." => "__"])
    end
    # stats is always available
    rimport(:stats; normalizenames=false)
end
