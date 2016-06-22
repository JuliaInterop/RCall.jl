"""
Parses an inline R script, substituting invalid "\$" signs for Julia symbols
"""
function render_rscript(script::Compat.String)
    symdict = OrderedDict{Compat.ASCIIString,Any}()
    sf = protect(rcall_p(:srcfile,"xx"))
    local val
    local status
    local msg

    try
        while true
            val, status, msg = parseVector(sexp(script), sf)

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
