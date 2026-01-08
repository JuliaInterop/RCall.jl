include("set_up_tests.jl")

@testset ExtendedTestSet "installation" include("installation.jl")

# before RCall does anything
const R_PPSTACKTOP_INITIAL = unsafe_load(cglobal((:R_PPStackTop, RCall.libR), Int))
@testset include("system_configuration.jl")

@testset ExtendedTestSet "RCall" begin
    @testset "Basic" include("basic.jl")

    @testset "Conversion" begin
        @testset "Base" include("convert/base.jl")
        @testset "Missing" include("convert/missing.jl")
        @testset "Datetime" include("convert/datetime.jl")
        @testset "Dataframe" include("convert/dataframe.jl")
        @testset "Categorical" include("convert/categorical.jl")
        @testset "Formula" include("convert/formula.jl")
        @testset "Namedtuple" include("convert/namedtuple.jl")
        @testset "Tuple" include("convert/tuple.jl")
        @testset "AxisArray" include("convert/axisarray.jl")
    end

    @testset "Macros" include("macros.jl")

    @testset "Namespaces" include("namespaces.jl")

    if TEST_REPL[]
        @testset "REPL" include("repl.jl")
    else
        @warn "Skipping REPL tests"
        @testset "REPL" begin
            @test_broken false
        end
    end

    @testset "IJulia" begin
        # the IJulia tests depend on the R graphics device being set up correctly,
        # which is non trivial on non-linux headless devices (e.g. CI)
        # it also uses the assumed path to Jupyter on unix
        if Sys.islinux()
            include("ijulia.jl")
        end
    end

    # make sure we're back where we started
@test unsafe_load(cglobal((:R_PPStackTop, RCall.libR), Int)) == R_PPSTACKTOP_INITIAL
end
