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

function load()
    for s in (:NaString, :BlankString, :BlankScalarString, :BaseSymbol,
            :BraceSymbol, :Bracket2Symbol, :BracketSymbol, :ClassSymbol, :DeviceSymbol,
            :DimNamesSymbol, :DimSymbol, :DollarSymbol, :DotsSymbol, :DoubleColonSymbol,
            :DropSymbol, :LastvalueSymbol, :LevelsSymbol, :MissingArg, :ModeSymbol,
            :NaRmSymbol, :NameSymbol, :NamesSymbol, :NamespaceEnvSymbol, :PackageSymbol,
            :PreviousSymbol, :QuoteSymbol, :RowNamesSymbol, :SeedsSymbol, :SortListSymbol,
            :SourceSymbol, :SpecSymbol, :TripleColonSymbol, :dot_defined, :dot_Method,
            :dot_packageName, :dot_target, :EmptyEnv, :GlobalEnv, :BaseEnv, :BaseNamespace,
            :NilValue, :UnboundValue)
        @eval begin
            try
                $s.p = unsafe_load(cglobal($(string(:R_,s)), typeof($s.p)))
            catch
                $s.p = unsafe_load(cglobal(($(string(:R_,s)), libR),typeof($s.p)))
            end
        end
    end
end

end # module

"""
R global Environment.

    globalEnv[:x] = 1
    globalEnv[:x]
"""
const globalEnv = Const.GlobalEnv
