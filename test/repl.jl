using REPL
import REPL: Terminals
using RCall

mutable struct FakeTerminal <: Terminals.UnixTerminal
    in_stream::Base.IO
    out_stream::Base.IO
    err_stream::Base.IO
    hascolor::Bool
    raw::Bool
    FakeTerminal(stdin,stdout,stderr,hascolor=true) =
        new(stdin,stdout,stderr,hascolor,false)
end

Terminals.hascolor(t::FakeTerminal) = t.hascolor
Terminals.raw!(t::FakeTerminal, raw::Bool) = t.raw = raw
Terminals.size(t::FakeTerminal) = (24, 80)

# fake repl

input = Pipe()
output = Pipe()
err = Pipe()
Base.link_pipe!(input, reader_supports_async=true, writer_supports_async=true)
Base.link_pipe!(output, reader_supports_async=true, writer_supports_async=true)
Base.link_pipe!(err, reader_supports_async=true, writer_supports_async=true)

repl = REPL.LineEditREPL(FakeTerminal(input.out, output.in, err.in), true)

repltask = @async begin
    REPL.run_repl(repl)
end

send_repl(x, enter=true) = write(input, enter ? "$x\n" : x)

function read_repl(io::IO, x)
    cache = Ref{Any}("")
    read_task = @task cache[] = readuntil(io, x)
    t = Base.Timer((_) -> Base.throwto(read_task,
                ErrorException("Expect \"$x\", but wait too long.")), 5)
    schedule(read_task)
    fetch(read_task)
    close(t)
    cache[]
end

check_repl_stdout(x) = length(read_repl(output, x)) > 0
check_repl_stderr(x) = length(read_repl(err, x)) > 0

# waiting for the repl
send_repl("using RCall")

RCall.RPrompt.repl_init(repl)

send_repl("\$", false)
@test check_repl_stdout("R> ")

send_repl("bar = 'apple'")
@test check_repl_stdout("bar = 'apple'")

send_repl("paste0('pine', bar)")
@test check_repl_stdout("pineapple")

send_repl("mtca\t", false)
@test check_repl_stdout("mtcars")

send_repl("")
@test check_repl_stdout("\n")

send_repl("\\alp\t", false)
@test check_repl_stdout("\\alpha")

send_repl("\t", false)
@test check_repl_stdout("α")

send_repl("")
@test check_repl_stdout("\n")

send_repl("foo]")
@test check_repl_stderr("unexpected")

send_repl("stop('something is wrong')")
@test check_repl_stderr("something is wrong")

send_repl("not_found")
@test check_repl_stderr("not found")

send_repl("\b", false)
@test check_repl_stdout("julia> ")

send_repl("x = \"orange\"")
@test check_repl_stdout("x = \"orange\"")

send_repl("\$", false)
@test check_repl_stdout("R> ")

send_repl("\$x")
@test check_repl_stdout("orange")

send_repl("\$not_found")
@test check_repl_stderr("UndefVarError")

send_repl("(x <- 1 + 1) # inline comment")
@test check_repl_stdout("[1] 2")

# check visibility

send_repl("'apple'")
send_repl("paste0('check', 'point')")
@test occursin("\"apple\"", read_repl(output, "checkpoint"))

send_repl("invisible('apple')")
send_repl("paste0('check', 'point')")
@test !occursin("\"apple\"", read_repl(output, "checkpoint"))

# bracked paste callback
send_repl("\e[200~1 + 1\n\n2 + 2\n3 + 3\e[201~\n")
@test check_repl_stdout("[1] 6")

send_repl("\e[200~1 + \n 1\n\e[201~")
@test check_repl_stdout("[1] 2")

send_repl("\e[200~1 + 1\e[201~ +")

@test RCall.RPrompt.repl_inited(repl)
