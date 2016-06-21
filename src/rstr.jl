"""
Parses an inline R script, substituting invalid "\$" signs for Julia symbols
"""
function parse_rscript(script::Compat.String)
    symdict = OrderedDict{Compat.ASCIIString,Any}()
    sf = protect(rcall_p(:srcfile,"xx"))
    local val
    local status
    local msg

    try
        while true
            val, status, msg = ParseVector(sexp(script), sf)

            if status == 1 || status == 2
                break
            end

            if !isascii(script)
                msg = "Unicode R scripts not supported, due to\n    https://bugs.r-project.org/bugzilla3/show_bug.cgi?id=16524"
                break
            end

            parsedata = protect(rcall_p(:getParseData, sf))
            n = length(parsedata[1])

            lineno = parsedata[1][n]
            charno = parsedata[2][n] # this is the character no., not byte number

            c = rcopy(Compat.UTF8String, parsedata[9][n])
            unprotect(1)

            c != "\$" && break

            # skip to string location
            i = start(script)
            for j = 1:lineno-1
                i = search(script,'\n',i)
                i = nextind(script,i)
            end
            for j = 1:charno-1
                i = nextind(script,i)
            end

            # assuming no unicode, see
            # https://bugs.r-project.org/bugzilla3/show_bug.cgi?id=16524
            i_stop = prevind(script,i)

            c,i = next(script,i)

            c != '\$' && break

            expr,i = parse(script,i,greedy=false)

            if isa(expr,Symbol)
                sym = "$expr"
            else
                sym = "($expr)"
                # if an expression has already appeared, we generate a new symbol so it will be evaluated twice (e.g. `R"$(rand(10)) == $(rand(10))"`)
                if haskey(symdict, sym)
                    sym *= "##$k"
                end
            end
            symdict[sym] = expr
            script = string(script[1:i_stop],"`#JL`\$`",sym,'`',script[i:end])
        end

    finally
        unprotect(1)
    end
    if status == 1
        return script, symdict, status, msg
    else
        return nothing, nothing, status, msg
    end
end


"""
    R"..."

An inline R expression, the result of which is evaluated and returned as an `RObject`.

It supports substitution of Julia variables and expressions via prefix with `\$` whenever
not valid R syntax (i.e. when not immediately following another completed R expression):

    R"glm(Sepal.Length ~ Sepal.Width, data=\$iris)"

It is also possible to pass Julia expressions:

    R"plot($(x -> exp(x).*sin(x)))"

All such Julia expressions are evaluated once, before the R expression is evaluated.

The expression does not support assigning to Julia variables, so the only way retrieve
values from R via the return value.

"""
macro R_str(script)
    script, symdict, status, msg = parse_rscript(script)
    status != 1 && error(msg)

    blk_ld = Expr(:block)
    for (rsym, expr) in symdict
        push!(blk_ld.args,:(env[$rsym] = $(esc(expr))))
    end
    quote
        let env = protect(newEnvironment())
            globalEnv["#JL"] = env
            try
                $blk_ld
            finally
                unprotect(1)
            end
            nothing
        end
        reval($script, globalEnv)
    end
end
