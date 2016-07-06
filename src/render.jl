"""
Render an inline R script, substituting invalid "\$" signs for Julia symbols
"""
function render(script::Compat.String)
    symdict = OrderedDict{Compat.String,Any}()
    local status
    local msg = ""
    while true
        status = parseVector(sexp(script))[2]
        if status != 1
            msg = getParseErrorMsg()
        end

        # break if not parse error (status = 3)
        (status != 3) && break

        # due to a bug in the R parser https://bugs.r-project.org/bugzilla3/show_bug.cgi?id=16524
        # parse and getParseData do not work with unicode
        # R_ParseContextLast and R_ParseContext are not documentated, but they seem to work

        # the position of the error byte
        b = Int(unsafe_load(cglobal((:R_ParseContextLast, libR), Cint)))
        # it is unsafe to use `unsafe_string` if the last byte is a part of a unicode,
        c = Char(unsafe_load(cglobal((:R_ParseContext, libR), Cchar)+b))
        c != '\$' && break

        ast,i = parse(script,b+1,greedy=false,raise=false)

        if isa(ast,Symbol)
            sym = "$ast"
        elseif isa(ast, Expr) && !(ast.head == :error || ast.head == :continue || ast.head == :incomplete)
            sym = "($ast)"
            # if an expression has already appeared, we generate a new symbol so it will be evaluated twice (e.g. `R"$(rand(10)) == $(rand(10))"`)
            if haskey(symdict, sym)
                sym *= "##$k"
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
        script = string(script[1:b-1],"`#JL`\$`",sym,'`',script[i:end])
    end

    return script, symdict, status, msg
end
