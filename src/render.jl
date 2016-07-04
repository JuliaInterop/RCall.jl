"""
Render an inline R script, substituting invalid "\$" signs for Julia symbols
"""
function render_rscript(script::Compat.String)
    symdict = OrderedDict{Compat.String,Any}()
    sf = protect(rcall_p(:srcfile,"xx"))
    local status
    local msg

    try
        while true
            val, status, msg = parseVector(sexp(script), sf)

            if status == 1 || status == 2
                break
            end

            # there is a bug in the R parser https://bugs.r-project.org/bugzilla3/show_bug.cgi?id=16524
            # R_ParseContextLast and R_ParseContext are not documentated, but they seem to work

            # the position of the error byte
            b = Int(unsafe_load(cglobal((:R_ParseContextLast, RCall.libR), Int32)))
            # it is unsafe to use `unsafe_string` if the last byte is a part of a unicode,
            c = Char(unsafe_load(cglobal((:R_ParseContext, RCall.libR), UInt8)+b))
            c != '\$' && break

            expr,i = parse(script,b+1,greedy=false)

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
            script = string(script[1:b-1],"`#JL`\$`",sym,'`',script[i:end])
        end
    finally
        unprotect(1) #sf
    end

    if status == 1
        return script, symdict, status, msg
    else
        return nothing, nothing, status, msg
    end
end
