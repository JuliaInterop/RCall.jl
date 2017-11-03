import Base: REPL, LineEdit, Terminals
using RCall

mutable struct FakeTerminal <: Base.Terminals.UnixTerminal
    in_stream::Base.IO
    out_stream::Base.IO
    err_stream::Base.IO
    hascolor::Bool
    raw::Bool
    FakeTerminal(stdin,stdout,stderr,hascolor=true) =
        new(stdin,stdout,stderr,hascolor,false)
end

Base.Terminals.hascolor(t::FakeTerminal) = t.hascolor
Base.Terminals.raw!(t::FakeTerminal, raw::Bool) = t.raw = raw
Base.Terminals.size(t::FakeTerminal) = (24, 80)

# fake repl

stdin_read,stdin_write = (Base.PipeEndpoint(), Base.PipeEndpoint())
stdout_read,stdout_write = (Base.PipeEndpoint(), Base.PipeEndpoint())
stderr_read,stderr_write = (Base.PipeEndpoint(), Base.PipeEndpoint())
Base.link_pipe(stdin_read,true,stdin_write,true)
Base.link_pipe(stdout_read,true,stdout_write,true)
Base.link_pipe(stderr_read,true,stderr_write,true)

repl = Base.REPL.LineEditREPL(FakeTerminal(stdin_read, stdout_write, stderr_write,false))

repltask = @async begin
    Base.REPL.run_repl(repl)
end

send_repl(x, enter=true) = write(stdin_write, enter ? "$x\n" : x)

function check_repl(io::IO, x)
    read_task = @task readuntil(io, x)
    t = Base.Timer((_) -> Base.throwto(read_task,
                ErrorException("Expect \"$x\", but wait too long.")), 5)
    schedule(read_task)
    wait(read_task)
    close(t)
    true
end

check_repl_stdout(x) = check_repl(stdout_read, x)
check_repl_stderr(x) = check_repl(stderr_read, x)

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
