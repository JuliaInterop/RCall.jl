import Base: +, -, *, /, ^

+(x::RObject, y::RObject) = rcall(Symbol("+"), x, y)
-(x::RObject, y::RObject) = rcall(Symbol("-"), x, y)
*(x::RObject, y::RObject) = rcall(Symbol("*"), x, y)
/(x::RObject, y::RObject) = rcall(Symbol("/"), x, y)
^(x::RObject, y::RObject) = rcall(Symbol("^"), x, y)
