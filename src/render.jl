"""
Render an inline R script, substituting invalid "\$" signs for Julia symbols
"""
function render(script::String)
    symdict = OrderedDict{String,Any}()
    local status
    local msg = ""
    local k = 0
    local c = ' '
    while true
        st = protect(sexp(script))
        sf = protect(rcall_p(:srcfile,"xx"))
        status = parseVector(st, sf)[2]
        unprotect(1)
        msg = status == 1 ? "" : getParseErrorMsg()

        # break if not parse error (status = 3)
        if status != 3
            unprotect(1)
            break
        else
            parsedata = protect(rcall_p(:getParseData,sf))
            n = length(parsedata[1])
            line = parsedata[1][n]
            col = parsedata[2][n]
            c = rcopy(String, parsedata[:text][n])[1]
            unprotect(2)
        end

        # break if the parse error is not caused by $
        c != '\$' && break

        index = 0
        for i in 1:(line-1)
            index = search(script, '\n', index+1)
        end
        for j in 1:col
            index = nextind(script, index)
        end

        try
            c = script[index]
        catch e
            c = ' '
        end
        if c != '\$'
            msg = "Error in locating julia expressions"
            break
        end

        ast,i = parse(script,index+1,greedy=false,raise=false)

        if isa(ast,Symbol)
            sym = "$ast"
        elseif isa(ast, Expr) && !(ast.head == :error || ast.head == :continue || ast.head == :incomplete)
            sym = "($ast)"
            # if an expression has already appeared, we generate a new symbol so it will be evaluated twice (e.g. `R"$(rand(10)) == $(rand(10))"`)
            if haskey(symdict, sym)
                sym *= "##$k"
                k = k + 1
            end
        elseif isa(ast, Expr) && (ast.head == :error || ast.head == :continue)
            status = 3
            msg = ast.args[1]
            break
        elseif isa(ast, Expr) && ast.head == :incomplete
            status = 2
            msg = ast.args[1]
            break
        else
            status = 3
            msg = "unknown render error"
            break
        end
        symdict[sym] = ast
        script = string(script[1:index-1], "`#JL`\$`",sym,'`', script[i:end])
    end

    return script, symdict, status, msg
end

"""
Prepare code for evaluating the julia expressions. When the code is execulated,
the results are stored in the R environment `#JL`.
"""
function prepare_inline_julia_code(symdict, escape::Bool=false)
    new_env = Expr(:(=), :env, Expr(:call, reval_p, Expr(:call, rparse_p, "`#JL` <- new.env()")))
    blk = Expr(:block)
    for (rsym, expr) in symdict
        push!(blk.args, Expr(:(=), Expr(:ref, :env, rsym), escape ? esc(expr) : expr))
    end
    Expr(:let, blk, new_env)
end
