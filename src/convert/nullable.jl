# conversion methods for Nullable

function rcopy(::Type{Nullable{T}}, s::Ptr{S}) where {T,S<:Sxp}
    length(s) == 1 || error("length of s must be 1.")
    if isnull(s[1]) || isNA(s[1])
        Nullable{T}()
    else
        Nullable{T}(rcopy(T, s))
    end
end


# Default behaviors of copying to Nullable

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
function sexp(::Type{S}, s::Nullable) where S<:Sxp
    if isnull(s)
        sexp(Const.NilValue)
    else
        sexp(S, s.value)
    end
end
