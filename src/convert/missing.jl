# IntSxp, RealSxp, CplxSxp, LglSxp, StrSxp, VecSxp to Array{Union{T, Missing}}
for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp, :VecSxp)
    @eval begin
        function rcopy(::Type{Array{Union{T, Missing}}}, s::Ptr{$S}) where T
            protect(s)
            v = Union{T, Missing}[isNA(e) ? missing : rcopy(T, e) for e in s]
            ret = reshape(v,size(s))
            unprotect(1)
            ret
        end
        function rcopy(::Type{Vector{Union{T, Missing}}}, s::Ptr{$S}) where T
            protect(s)
            ret = Union{T, Missing}[isNA(e) ? missing : rcopy(T, e) for e in s]
            unprotect(1)
            ret
        end
    end
end

## Array{Union{T, Missing}} to sexp conversion.

for (J,S) in ((:Integer, :IntSxp),
                 (:AbstractFloat, :RealSxp),
                 (:Complex, :CplxSxp),
                 (:Bool, :LglSxp),
                 (:AbstractString, :StrSxp))
    @eval begin
        function sexp(::Type{$S}, v::Array{Union{T, Missing}}) where T <: $J
            rv = protect(allocArray($S, size(v)...))
            try
                for (i, x) in enumerate(v)
                    if ismissing(x)
                        rv[i] = naeltype($S)
                    else
                        rv[i] = x
                    end
                end
            finally
                unprotect(1)
            end
            rv
        end
    end
end
