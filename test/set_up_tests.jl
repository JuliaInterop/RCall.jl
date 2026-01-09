using AxisArrays
using Dates
using Logging
using RCall
using Test
using TestSetExtensions

using Base: VersionNumber
using DataStructures: OrderedDict
using RCall: RClass

const TEST_REPL = Ref(parse(Bool, get(ENV, "TEST_REPL", "true")))
const HOMEDIR_AT_STARTUP = homedir()
