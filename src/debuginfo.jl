"""
Print some useful information about the current RCall.jl setup.
If `all` is false, only RCall.jl information is printed, otherwise
information about your Julia and R setup is printed as well.
This function is intended to be used in the Julia REPL only.
"""
function debuginfo(; all=true)
    if all && !isdefined(Main, :versioninfo)
        error("This function is intended to be used in the Julia REPL only.")
    end
    if all
        println("RCall.jl information:")
    end
    version = pkgversion(RCall)
    prefix = all ? "\t" : ""
    println("$(prefix)RCall.jl version $version")
    println("$(prefix)R location configured with Preferences.jl: $Rhome_set_as_preference")
    println("$(prefix)RCall.jl managed R using Conda.jl: $conda_provided_r")
    println("$(prefix)Rhome: $Rhome")
    println("$(prefix)libR: $libR")
    if all
        println()
        println("Julia information:")
        buffer = IOBuffer()
        Main.versioninfo(buffer)
        seek(buffer, 0)
        for line in eachline(buffer)
            println("\t" * line)
        end
        println()
        println("R information:")
        lines = reval("capture.output(sessionInfo())")
        for line in lines
            println("\t" * rcopy(line))
        end
    end
end
