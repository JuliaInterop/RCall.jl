import Base: +, -, *, /, ^

+(x::RObject, y::RObject) = rcall(symbol("+"), x, y)
-(x::RObject, y::RObject) = rcall(symbol("-"), x, y)
*(x::RObject, y::RObject) = rcall(symbol("*"), x, y)
/(x::RObject, y::RObject) = rcall(symbol("/"), x, y)
^(x::RObject, y::RObject) = rcall(symbol("^"), x, y)
