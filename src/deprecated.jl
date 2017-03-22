@deprecate isNA(x) isna(x)
@deprecate anyNA(x) anyna(x)
@deprecate getAttrib getattrib
@deprecate setAttrib! setattrib!
@deprecate getNames getnames
@deprecate setNames! setnames!
@deprecate getClass getclass
@deprecate setClass! setclass!

function rcopy(str::AbstractString)
    Base.depwarn("""
        `rcopy(str::AbstractString)` is deprecated, use `rcopy(reval(str))`
        or rcopy(R"<your code>") instead.
    """, :rcopy)
    rcopy(reval(str))
end
function rcopy{T}(::Type{T}, str::AbstractString)
    Base.depwarn("""
        `rcopy{T}(::Type{T}, str::AbstractString)` is deprecated, use
        `rcopy(T, reval(str))` or rcopy(T, R"<your code>") instead.
    """, :rcopy)
    rcopy(T, reval(str))
end
@deprecate rcopy(sym::Symbol) rcopy(reval(sym))
@deprecate rcopy{T}(::Type{T}, sym::Symbol) rcopy(T, reval(sym))
