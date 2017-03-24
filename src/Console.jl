module Console

import Base.write
import ..REvalutionError

# used in write_output and write_error
type WarningIO <: IO end
type ErrorIO <: IO end

const error_device = ErrorIO()
const warning_device = WarningIO()

# mainly use to prevent write_output stealing rprint output
output_is_locked = false

write(io::WarningIO, s::String) = warn("RCall.jl: ", s)
write(io::ErrorIO, s::String) = throw(REvalutionError("RCall.jl: " * s))

const output_buffer_ = PipeBuffer()
const error_buffer = PipeBuffer()

function write_console_ex(buf::Ptr{UInt8},buflen::Cint,otype::Cint)
    if otype == 0
        unsafe_write(output_buffer_, buf, buflen)
    else
        unsafe_write(error_buffer, buf, buflen)
    end
    return nothing
end

function write_output(io::IO; force::Bool=false)
    # dump output_buffer_'s content when it is not locked
    if (!output_is_locked || force) && nb_available(output_buffer_) != 0
        write(io, String(take!(output_buffer_)))
    end
    nothing
end

function write_error(io::IO)
    if nb_available(error_buffer) != 0
        write(io, String(take!(error_buffer)))
    end
    nothing
end

function lock_output()
    global output_is_locked
    output_is_locked = true
end

function unlock_output()
    global output_is_locked
    output_is_locked = false
end

end # Console
