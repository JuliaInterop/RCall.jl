# library
# Since @rimport and @rlibrary create module objects which may be conflict with other objects,
# it is safer to place them at the end of the test.
@rimport MASS as mass
@test_approx_eq rcopy(rcall(mass.ginv, RObject([1 2; 0 4]))) [1 -0.5; 0 0.25]
@rlibrary MASS
@test_approx_eq rcopy(rcall(ginv, RObject([1 2; 0 4]))) [1 -0.5; 0 0.25]
