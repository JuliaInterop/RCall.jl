module Const

import ..libR, ..RObject, ..NilSxp, ..SymSxp, ..EnvSxp, ..SxpHead, ..StrSxp, ..CharSxp


const NaInt  = typemin(Cint)
const NaReal = reinterpret(Float64,0x7ff00000000007a2)


const NaString           = RObject{CharSxp}()
const BlankString        = RObject{CharSxp}()

const BlankScalarString  = RObject{StrSxp}()

const BaseSymbol         = RObject{SymSxp}() # base
const BraceSymbol        = RObject{SymSxp}() # {
const Bracket2Symbol     = RObject{SymSxp}() # [[
const BracketSymbol      = RObject{SymSxp}() # [
const ClassSymbol        = RObject{SymSxp}() # class
const DeviceSymbol       = RObject{SymSxp}() # .Device
const DimNamesSymbol     = RObject{SymSxp}() # dimnames
const DimSymbol          = RObject{SymSxp}() # dim
const DollarSymbol       = RObject{SymSxp}() # $
const DotsSymbol         = RObject{SymSxp}() # ...
const DoubleColonSymbol  = RObject{SymSxp}() # ::
const DropSymbol         = RObject{SymSxp}() # drop
const LastvalueSymbol    = RObject{SymSxp}() # .Last.value
const LevelsSymbol       = RObject{SymSxp}() # levels
const MissingArg         = RObject{SymSxp}()
const ModeSymbol         = RObject{SymSxp}() # mode
const NaRmSymbol         = RObject{SymSxp}() # na.rm
const NameSymbol         = RObject{SymSxp}() # name
const NamesSymbol        = RObject{SymSxp}() # names
const NamespaceEnvSymbol = RObject{SymSxp}() # .__NAMESPACE__.
const PackageSymbol      = RObject{SymSxp}() # package
const PreviousSymbol     = RObject{SymSxp}() # previous
const QuoteSymbol        = RObject{SymSxp}() # quote
const RowNamesSymbol     = RObject{SymSxp}() # row.names
const SeedsSymbol        = RObject{SymSxp}() # .Random.seed
const SortListSymbol     = RObject{SymSxp}() # sort.lis
const SourceSymbol       = RObject{SymSxp}() # source
const SpecSymbol         = RObject{SymSxp}() # spec
const TripleColonSymbol  = RObject{SymSxp}() # :::
const dot_defined        = RObject{SymSxp}() # .defined
const dot_Method         = RObject{SymSxp}() # .Method
const dot_packageName    = RObject{SymSxp}() # .packageName
const dot_target         = RObject{SymSxp}() # .target

const EmptyEnv           = RObject{EnvSxp}()
const GlobalEnv          = RObject{EnvSxp}()
const BaseEnv            = RObject{EnvSxp}()
const BaseNamespace      = RObject{EnvSxp}()

const NilValue           = RObject{NilSxp}()
const UnboundValue       = RObject{SxpHead}()

macro load_const(s)
    :($s.p = unsafe_load(cglobal(($(string(:R_,s)),libR),typeof($s.p))))
end

function load()
    @load_const NaString
    @load_const BlankString

    @load_const BlankScalarString

    @load_const BaseSymbol
    @load_const BraceSymbol
    @load_const Bracket2Symbol
    @load_const BracketSymbol
    @load_const ClassSymbol
    @load_const DeviceSymbol
    @load_const DimNamesSymbol
    @load_const DimSymbol
    @load_const DollarSymbol
    @load_const DotsSymbol
    @load_const DoubleColonSymbol
    @load_const DropSymbol
    @load_const LastvalueSymbol
    @load_const LevelsSymbol
    @load_const MissingArg
    @load_const ModeSymbol
    @load_const NaRmSymbol
    @load_const NameSymbol
    @load_const NamesSymbol
    @load_const NamespaceEnvSymbol
    @load_const PackageSymbol
    @load_const PreviousSymbol
    @load_const QuoteSymbol
    @load_const RowNamesSymbol
    @load_const SeedsSymbol
    @load_const SortListSymbol
    @load_const SourceSymbol
    @load_const SpecSymbol
    @load_const TripleColonSymbol
    @load_const dot_defined
    @load_const dot_Method
    @load_const dot_packageName
    @load_const dot_target

    @load_const EmptyEnv
    @load_const GlobalEnv
    @load_const BaseEnv
    @load_const BaseNamespace

    @load_const NilValue
    @load_const UnboundValue
end

end # module

"""
R global Environment.

    globalEnv[:x] = 1
    globalEnv[:x]
"""
const globalEnv = Const.GlobalEnv
