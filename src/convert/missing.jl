# sexp to Array{Union{T, Missing}}
for S in (:IntSxp, :RealSxp, :CplxSxp, :LglSxp, :StrSxp)
    @eval begin
        function rcopy(::Type{Array{Union{T, Missing}}}, s::Ptr{$S}) where T
            protect(s)
            v = try
                Union{T, Missing}[isNA(e) ? missing : rcopy(T,e) for e in s]
            finally
                unprotect(1)
            end
            reshape(v,size(s))
        end
        function rcopy(::Type{Vector{Union{T, Missing}}}, s::Ptr{$S}) where T
            protect(s)
            v = try
                Union{T, Missing}[isNA(e) ? missing : rcopy(T,e) for e in s]
            finally
                unprotect(1)
            end
            v
        end
    end
end

## Array{Union{T, Missing}} to sexp conversion.

for (J, S, C) in ((:Integer, :IntSxp, :integer),
                 (:AbstractFloat, :RealSxp, :numeric),
                 (:Complex, :CplxSxp, :complex),
                 (:Bool, :LglSxp, :logical),
                 (:AbstractString, :StrSxp, :character))
    @eval begin
        function sexp(::Type{RClass{$(QuoteNode(C))}}, v::AbstractArray{Union{T, Missing}}) where T <: $J
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
