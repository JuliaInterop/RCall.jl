module Console

import ..REvalutionError


# used in flush_output and flush_error
type ErrorIO <: IO end


# mainly use to prevent flush_output stealing rprint output
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

function flush_output(io::IO; force::Bool=false)
    # dump output_buffer_'s content when it is not locked
    if (!output_is_locked || force) && nb_available(output_buffer_) != 0
        write(io, String(take!(output_buffer_)))
    end
    nothing
end

function flush_error(io::IO; is_warning::Bool=false)
    if nb_available(error_buffer) != 0
        write(io, String(take!(error_buffer)))
    end
    nothing
end

function flush_error(io::ErrorIO; is_warning::Bool=false)
    if nb_available(error_buffer) != 0
        s = String(take!(error_buffer))
        if is_warning
            warn("RCall.jl: ", s)
        else
            throw(REvalutionError("RCall.jl: " * s))
        end
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

const error_device = Console.ErrorIO()
