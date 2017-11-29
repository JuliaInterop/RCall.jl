module IJuliaHooks
    using RCall
    function ijulia_init()
        Base.depwarn("""
            `Use RCall.ijulia_init() instead.`.
        """, :ijulia_init)
        RCall.ijulia_init()
    end

    function ijulia_setdevice(args...; kwargs...)
        Base.depwarn("""
            `Use RCall.ijulia_setdevice(...) instead.`.
        """, :ijulia_init)
        RCall.ijulia_setdevice(args...; kwargs...)
    end
end
