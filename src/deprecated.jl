for sym in (:isArray,:isComplex,:isEnvironment,:isExpression,:isFactor,
            :isFrame,:isFree,:isFunction,:isInteger,:isLanguage,:isList,
            :isLogical,:isSymbol,:isMatrix,:isNewList,:isNull,:isNumeric,
            :isNumber,:isObject,:isOrdered,:isPairListSxp,:isPrimitiveSxp,
            :isReal,:isS4,:isString,:isTs,:isUnordered,:isUnsorted,
            :isUserBinop,:isValidString,:isValidStringF,:isVector,
            :isVectorAtomicSxp,:isVectorizable,:isVectorListSxp)
    lsym = Compat.Symbol(lowercase(string(sym)))
    @eval begin
        @deprecate $sym{S<:Sxp}(s::Ptr{S}) $lsym(s)
    end
end

@deprecate isNA(x) isna(x)
@deprecate anyNA(x) anyna(x)
@deprecate getAttrib getattrib
@deprecate setAttrib! setattrib!
@deprecate getNames getnames
@deprecate setNames! setnames!
@deprecate getClass getclass
@deprecate setClass! setclass!
