# library
# Since @rimport and @rlibrary create module objects which may be conflict with other objects,
# it is safer to place them at the end of the tests.

module NamespaceTests
    using RCall
    using Test

    @rimport MASS
    @test rcopy(rcall(MASS.ginv, RObject([1 2; 0 4]))) ≈ [1 -0.5; 0 0.25]
    @rimport MASS as mass
    @test rcopy(rcall(mass.ginv, RObject([1 2; 0 4]))) ≈ [1 -0.5; 0 0.25]
    @rlibrary MASS
    @test rcopy(rcall(ginv, RObject([1 2; 0 4]))) ≈ [1 -0.5; 0 0.25]

end
