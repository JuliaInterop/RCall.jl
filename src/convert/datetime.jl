# Date and DateTime

rcopy(::Type{Date}, s::RealSxpPtr) = rcopy(Date, s[1])
rcopy(::Type{DateTime}, s::RealSxpPtr) = rcopy(DateTime, s[1])

rcopy(::Type{Date}, x::Float64) = isnan(x)? 0: convert(Date, x) + Dates.Day(719163)
rcopy(::Type{DateTime}, x::Float64) = isnan(x)? 0: convert(DateTime, x*1000) + Dates.Day(719163)


function sexp(RealSxp, d::Date)
    res = sexp(RealSxp, convert(Float64, d - Dates.Day(719163)))
    setclass!(res, sexp("Date"))
    res
end
function sexp(RealSxp, a::AbstractArray{Date})
    res = sexp(RealSxp, convert(AbstractArray{Float64}, a - Dates.Day(719163)))
    setclass!(res, sexp("Date"))
    res
end
function sexp(RealSxp, d::DateTime)
    res = sexp(RealSxp, convert(Float64, d - Dates.Day(719163)) / 1000)
    setclass!(res, sexp(["POSIXct", "POSIXt"]))
    setattrib!(res, "tzone", sexp("UTC"))
    res
end
function sexp(RealSxp, a::AbstractArray{DateTime})
    res = sexp(RealSxp, convert(AbstractArray{Float64}, a - Dates.Day(719163)) / 1000)
    setclass!(res, sexp(["POSIXct", "POSIXt"]))
    setattrib!(res, "tzone", sexp("UTC"))
    res
end
