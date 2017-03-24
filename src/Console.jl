module Console

import ..WarningIO, ..ErrorIO

const warning_device = WarningIO()
const error_device = ErrorIO()

const default_devices = (STDOUT, warning_device, error_device)

# mainly use to prevent write_output stealing rprint output
output_is_locked = false

const output_buffer_ = PipeBuffer()
const error_buffer = PipeBuffer()

"""
R API callback to write console output.
"""
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
