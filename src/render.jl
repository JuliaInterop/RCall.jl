"""
Render an inline R script, substituting invalid "\$" signs for Julia symbols
"""
function render(script::String)
    symdict = OrderedDict{String,Any}()
    local status
    local msg = ""
    local k = 0
    while true
        status = parseVector(sexp(script))[2]
        msg = status == 1 ? "" : getParseErrorMsg()

        # break if not parse error (status = 3)
        (status != 3) && break

        # due to a bug in the R parser https://bugs.r-project.org/bugzilla3/show_bug.cgi?id=16524
        # unicode script parse error column location does not work
        # for unicode < 256 bytes, R_ParseContextLast is used instead

        if isascii(script)
            line = Int(unsafe_load(cglobal((:R_ParseContextLine, libR), Cint)))
            col = Int(unsafe_load(cglobal((:R_ParseErrorCol, libR), Cint)))
            index = 0
            for i in 1:(line-1)
                index = search(script, '\n', index+1)
            end
            b = index + col
            c = script[b]
            c != '\$' && break

        else
            # the position of the error byte
            b = Int(unsafe_load(cglobal((:R_ParseContextLast, libR), Cint)))
            # it is unsafe to use `unsafe_string` if the last byte is a part of a unicode,
            c = Char(unsafe_load(cglobal((:R_ParseContext, libR), Cchar)+b))
            c != '\$' && break

            # `R_ParseContextLast` is only good for script < 256 bytes since `R_ParseContext` uses
            # circular buffer
            if sizeof(script) >= 256
                msg = "Subsitution in unicode expression of length >= 256 bytes is not supported."
                break
            end
        end

        ast,i = parse(script,b+1,greedy=false,raise=false)

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
        script = string(script[1:b-1],"`#JL`\$`",sym,'`',script[i:end])
    end

    return script, symdict, status, msg
end
