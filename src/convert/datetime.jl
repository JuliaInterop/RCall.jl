# Date and DateTime

rcopy(::Type{Date}, s::RealSxpPtr) = rcopy(Date, s[1])
rcopy(::Type{DateTime}, s::RealSxpPtr) = rcopy(DateTime, s[1])

rcopy(::Type{Date}, x::Float64) = Date(Dates.UTInstant(Dates.Day((isnan(x)? 0: x) + 719163)))
rcopy(::Type{DateTime}, x::Float64) =
    DateTime(Dates.UTInstant(Dates.Millisecond(((isnan(x)? 0: x) + 62135683200) * 1000)))

function sexp(RealSxp, d::Date)
    res = sexp(RealSxp, Float64(Dates.value(d)) - 719163)
    setclass!(res, sexp("Date"))
    res
end
function sexp(RealSxp, a::AbstractArray{Date})
    res = sexp(RealSxp, map((x) -> Float64(Dates.value(x)) - 719163, a))
    setclass!(res, sexp("Date"))
    res
end
function sexp(RealSxp, d::DateTime)
    res = sexp(RealSxp, Float64(Dates.value(d) / 1000) - 62135683200)
    setclass!(res, sexp(["POSIXct", "POSIXt"]))
    setattrib!(res, "tzone", sexp("UTC"))
    res
end
function sexp(RealSxp, a::AbstractArray{DateTime})
    res = sexp(RealSxp, map((x) -> Float64(Dates.value(x) / 1000) - 62135683200, a))
    setclass!(res, sexp(["POSIXct", "POSIXt"]))
    setattrib!(res, "tzone", sexp("UTC"))
    res
end
