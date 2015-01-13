## SEXPREC types as defined in ENV["R_INCLUDE_DIR"]/Rinternals.h

const NILSXP     =  0 # NULL in R
const SYMSXP     =  1 # R Symbol
const LISTSXP    =  2 # internal "pairs list", the R list type is 19
const CLOSXP     =  3 # closures
const ENVSXP     =  4 # environments
const PROMSXP    =  5 # promises: unevaluated closure arguments
const LANGSXP    =  6 # language constructs (special lists 
const SPECIALSXP =  7 # special forms 
const BUILTINSXP =  8 # builtin non-special forms 
const CHARSXP    =  9 # "scalar" string type (internal only
const LGLSXP     = 10 # logical vectors 
# 11 and 12 were factors and ordered factors in the 1990s 
const INTSXP     = 13 # integer vectors 
const REALSXP    = 14 # real variables 
const CPLXSXP    = 15 # complex variables 
const STRSXP     = 16 # string vectors 
const DOTSXP     = 17 # dot-dot-dot object 
const ANYSXP     = 18 # make "any" args work.
const VECSXP     = 19 # generic vectors 
const EXPRSXP    = 20 # expressions vectors 
const BCODESXP   = 21 # byte code 
const EXTPTRSXP  = 22 # external pointer 
const WEAKREFSXP = 23 # weak reference 
const RAWSXP     = 24 # raw bytes 
const S4SXP      = 25 # S4, non-vector 
