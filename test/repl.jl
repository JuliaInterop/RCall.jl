import Base: REPL, LineEdit, Terminals
using RCall
using Compat

if !Compat.is_windows()

    type FakeTerminal <: Base.Terminals.UnixTerminal
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
    # repl.specialdisplay = Base.REPL.REPLDisplay(repl)
    repl.history_file = false

    repltask = @async begin
        Base.REPL.run_repl(repl)
    end

    sendrepl(cmd) = write(stdin_write,"inc || wait(b); r = $cmd; notify(c); r\r")
    inc = false
    b = Condition()
    c = Condition()
    sendrepl("\"Hello REPL\"")
    inc=true
    begin
        notify(b)
        wait(c)
    end

    RCall.repl_init(repl)

    write(stdin_write, "using RCall\n")
    write(stdin_write, "\$")
    readuntil(stdout_read, "R> ")

    write(stdin_write, "bar = 'apple'\n")
    readuntil(stdout_read, "bar = 'apple'")

    write(stdin_write, "paste0('pine', bar)\n")
    readuntil(stdout_read, "pineapple")

    write(stdin_write, "\n")
    readuntil(stdout_read, "\n")

    write(stdin_write, "foo]\n")
    readuntil(stderr_read, "unexpected")
    readuntil(stderr_read, "\n")

    write(stdin_write, "stop('something is wrong')\n")
    readuntil(stderr_read, "something is wrong")

end
