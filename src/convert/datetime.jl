# Date and DateTime

# R -> Julia

rcopy(::Type{Date}, s::Ptr{RealSxp}) = rcopy(Date, s[1])
rcopy(::Type{DateTime}, s::Ptr{RealSxp}) = rcopy(DateTime, s[1])

rcopy(::Type{Date}, x::Float64) = Date(Dates.UTInstant(Dates.Day((isnan(x) ? 0 : x) + 719163)))
rcopy(::Type{DateTime}, x::Float64) =
    DateTime(Dates.UTInstant(Dates.Millisecond(((isnan(x) ? 0 : x) + 62135683200) * 1000)))

# implicit conversion `rcopy(d)`.
function rcopytype(::Type{RClass{:Date}}, s::Ptr{RealSxp})
    if length(s) == 1
        return Date
    elseif anyna(s)
        return DataArray{Date}
    else
        return Array{Date}
    end
end
function rcopytype(::Type{RClass{:POSIXct}}, s::Ptr{RealSxp})
    if length(s) == 1
        return DateTime
    elseif anyna(s)
        return DataArray{DateTime}
    else
        return Array{DateTime}
    end
end

# implicit Array conversion `rcopy(Array, d)`.
eltype(::Type{RClass{:Date}}, s::Ptr{RealSxp}) = Date
eltype(::Type{RClass{:POSIXct}}, s::Ptr{RealSxp}) = DateTime

# Julia -> R

function sexp(RealSxp, d::Date)
    res = protect(sexp(RealSxp, Float64(Dates.value(d)) - 719163))
    setclass!(res, sexp("Date"))
    unprotect(1)
    res
end
function sexp(RealSxp, a::Array{Date})
    res = protect(sexp(RealSxp, map((x) -> Float64(Dates.value(x)) - 719163, a)))
    setclass!(res, sexp("Date"))
    unprotect(1)
    res
end
function sexp(RealSxp, d::DateTime)
    res = protect(sexp(RealSxp, Float64(Dates.value(d) / 1000) - 62135683200))
    setclass!(res, sexp(["POSIXct", "POSIXt"]))
    setattrib!(res, "tzone", sexp("UTC"))
    unprotect(1)
    res
end
function sexp(RealSxp, a::Array{DateTime})
    res = protect(sexp(RealSxp, map((x) -> Float64(Dates.value(x) / 1000) - 62135683200, a)))
    setclass!(res, sexp(["POSIXct", "POSIXt"]))
    setattrib!(res, "tzone", sexp("UTC"))
    unprotect(1)
    res
end
