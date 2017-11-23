# conversion methods for NullableArrays

function rcopy(::Type{Nullable{T}}, s::Ptr{S}) where {T,S<:Sxp}
    length(s) == 1 || error("length of s must be 1.")
    if isNA(s[1])
        Nullable{T}()
    else
        Nullable{T}(rcopy(T, s))
    end
end


# Default behaviors of copying R vectors to nullablearrays

for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp)
    @eval begin
        function rcopy(::Type{Nullable}, s::Ptr{$S})
            protect(s)
            try
                class = rcopy(Symbol, getclass(s, true))
                return rcopy(Nullable{eltype(RClass{class}, s)}, s)
            finally
                unprotect(1)
            end
        end
    end
end

# Nullable to sexp conversion.
for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp)
    @eval begin
        function sexp(::Type{$S}, x::Nullable)
            if isnull(x)
                return sexp($S, naeltype($S))
            else
                return sexp($S, x.value)
            end
        end
    end
end
