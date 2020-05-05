# Date and DateTime

# R -> Julia

rcopy(::Type{Date}, s::Ptr{RealSxp}) = rcopy(Date, s[1])
rcopy(::Type{DateTime}, s::Ptr{RealSxp}) = rcopy(DateTime, s[1])

rcopy(::Type{Date}, x::Float64) = Date(Dates.UTInstant(Dates.Day((isnan(x) ? 0 : x) + 719163)))
rcopy(::Type{DateTime}, x::Float64) =
    DateTime(Dates.UTInstant(Dates.Millisecond(((isnan(x) ? 0 : x) + 62135683200) * 1000)))

# implicit conversion `rcopy(d)`.
function rcopytype(::Type{RClass{:Date}}, s::Ptr{RealSxp})
    if anyna(s)
        length(s) == 1 ? Missing : Array{Union{Date, Missing}}
    else
        length(s) == 1 ? Date : Array{Date}
    end
end
function rcopytype(::Type{RClass{:POSIXct}}, s::Ptr{RealSxp})
    if anyna(s)
        length(s) == 1 ? Missing : Array{Union{DateTime, Missing}}
    else
        length(s) == 1 ? DateTime : Array{DateTime}
    end
end

# implicit Array conversion `rcopy(Array, d)`.
function eltype(::Type{RClass{:Date}}, s::Ptr{RealSxp})
    if anyna(s)
        Union{Date, Missing}
    else
        Date
    end
end
function eltype(::Type{RClass{:POSIXct}}, s::Ptr{RealSxp})
    if anyna(s)
        Union{DateTime, Missing}
    else
        DateTime
    end
end

# Julia -> R

function sexp(::Type{RClass{:Date}}, d::Date)
    res = protect(sexp(RClass{:numeric}, Float64(Dates.value(d)) - 719163))
    setclass!(res, sexp("Date"))
    unprotect(1)
    res
end
function sexp(::Type{RClass{:Date}}, a::AbstractArray{Date})
    res = protect(sexp(RClass{:numeric}, map((x) -> Float64(Dates.value(x)) - 719163, a)))
    setclass!(res, sexp("Date"))
    unprotect(1)
    res
end
function sexp(::Type{RClass{:Date}}, a::AbstractArray{Union{Date, Missing}})
    rv = protect(allocArray(RealSxp, size(a)...))
    try
        for (i, x) in enumerate(a)
            if ismissing(x)
                rv[i] = Const.NaReal
            else
                rv[i] = Float64(Dates.value(x)) - 719163
            end
        end
        setclass!(rv, sexp("Date"))
    finally
        unprotect(1)
    end
    rv
end
function sexp(::Type{RClass{:POSIXct}}, d::DateTime)
    res = protect(sexp(RClass{:numeric}, Float64(Dates.value(d) / 1000) - 62135683200))
    setclass!(res, sexp(["POSIXct", "POSIXt"]))
    setattrib!(res, "tzone", "UTC")
    unprotect(1)
    res
end
function sexp(::Type{RClass{:POSIXct}}, a::AbstractArray{DateTime})
    res = protect(sexp(RClass{:numeric}, map((x) -> Float64(Dates.value(x) / 1000) - 62135683200, a)))
    setclass!(res, sexp(["POSIXct", "POSIXt"]))
    setattrib!(res, "tzone", "UTC")
    unprotect(1)
    res
end
function sexp(::Type{RClass{:POSIXct}}, a::AbstractArray{Union{DateTime, Missing}})
    rv = protect(allocArray(RealSxp, size(a)...))
    try
        for (i, x) in enumerate(a)
            if ismissing(x)
                rv[i] = Const.NaReal
            else
                rv[i] = Float64(Dates.value(x) / 1000) - 62135683200
            end
        end
        setclass!(rv, sexp(["POSIXct", "POSIXt"]))
        setattrib!(rv, "tzone", "UTC")
    finally
        unprotect(1)
    end
    rv
end
