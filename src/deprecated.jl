module IJuliaHooks
    using RCall
    function ijulia_init()
        Base.depwarn("""
            `Use RCall.ijulia_init() instead.`.
        """, :ijulia_init)
        RCall.ijulia_init()
    end
end
