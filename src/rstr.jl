
# Only works for ASCII, as UTF-8 character numbers are incorrect, see https://bugs.r-project.org/bugzilla3/show_bug.cgi?id=16524
rscript(script::AbstractString) = error("Unicode R scripts not supported by R_str, due to\n    https://bugs.r-project.org/bugzilla3/show_bug.cgi?id=16524")

"""
Parses an inline R script, substituting invalid "\$" signs for Julia symbols
"""
function rscript(script::ASCIIString)
    sf = protect(rcall_p(:srcfile,"xx"))
    status = Array(Cint,1)
    k = 1
    rsyms = ASCIIString[]
    exprs = Any[]
    symdict = OrderedDict{ASCIIString,Any}()
    local ret, parsedata

    try
        while true
            # attempt to parse string
            ret = ccall((:R_ParseVector,libR),UnknownSxpPtr,
                        (Ptr{StrSxp},Cint,Ptr{Cint},Ptr{EnvSxp}),
                        sexp(script),-1,status,sf)

            if status[1] == 2
                error("RCall.jl incomplete R expression")
            end

            parsedata = protect(rcall_p(:getParseData,sf))
            n = length(parsedata[1])

            lineno = parsedata[1][n]
            charno = parsedata[2][n] # this is the character no., not byte numbe

            c = rcopy(UTF8String,parsedata[9][n])
            unprotect(1)

            if status[1] == 1
                break # valid R string
            end

            if  c != "\$"
                error("RCall.jl: invalid R expression")
            end

            # skip to string location
            i = start(script)
            for j = 1:lineno-1
                i = search(script,'\n',i)
                i = nextind(script,i)
            end
            for j = 1:charno-1
                i = nextind(script,i)
            end

            # now script[i] == '\$'
            # assuming no unicode, see
            # https://bugs.r-project.org/bugzilla3/show_bug.cgi?id=16524
            i_stop = prevind(script,i)
            
            c,i = next(script,i)
            c == '\$' || error("RCall.jl: incorrect R parsing")

            expr,i = parse(script,i,greedy=false)

            if isa(expr,Symbol)
                sym = "\$$expr"
            else
                sym = "\$($expr)"
                # if an expression has already appeared, we generate a new symbol so it will be evaluated twice (e.g. `R"$(rand(10)) == $(rand(10))"`)
                if haskey(symdict, sym)
                    sym *= "##$k"
                end
            end
            symdict[sym] = expr

            script = string(script[1:i_stop],'`',sym,'`',script[i:end])
        end
    finally
        unprotect(1)
    end
    return script, symdict
end

"""
Allows inline R scripts, e.g

    foo = R"glm(Sepal.Length ~ Sepal.Width, data=\$iris)"

Notes:
 - All Julia expressions are evaluated before the R expression.
 - Does not yet support assigning to Julia variables, so can only return results.
 - Is evaluated in it's own R environment. You can assign to the global environment by using the double-assignment operator `<<-`.
"""
macro R_str(script)
    script, symdict = rscript(script)    

    blk_ld = Expr(:block)
    for (rsym, expr) in symdict
        push!(blk_ld.args,:(env[$rsym] = $(esc(expr))))
    end
    quote
        env = newEnvironment()
        protect(env)
        $blk_ld
        ret = reval($script, env)
        unprotect(1)
        ret
    end
end