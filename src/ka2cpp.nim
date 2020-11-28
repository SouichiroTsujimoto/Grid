import ka2token, ka2node, ka2token, ka2error
import strutils, tables

#------↓仮↓------

type codeParts = tuple
  Type: string
  Code: string

type IdentInfo* = ref object of RootObj
  Type*:        string
  contents*:    seq[codeParts]
  path:         int
  mutable*:     bool
  delete*:      bool

var
  #                      ↓名前    ↓情報
  identTable = initTable[string, IdentInfo]()
  #                      ↓ネストの深さ   ↓そのスコープに含まれる変数
  scopeTable = initTable[int,         seq[string]]()
  nesting = 0

proc initTables*() =
  identTable = initTable[string, IdentInfo]()
  scopeTable = initTable[int, seq[string]]()
  nesting = 0

proc removeT(Type: string): string =
  if Type[0] == 'T' and Type[1] == '_':
    return Type[2..Type.len()-1]
  else:
    return Type

proc addSemicolon(parts: var seq[codeParts]) =
  let tail = parts[parts.len()-1]
  if tail.Type != SEMICOLON:
    parts.add((SEMICOLON, ";"))

proc addScopeTable(ident: string, n: int) =
  if scopeTable.contains(n):
    var flag = false
    for element in scopeTable[n]:
      if element == ident:
        flag = true
    # まだ登録されていなければ追加する
    if flag == false:
      scopeTable[n].add(ident)
  else:
    scopeTable[n] = @[ident]
  
proc deleteScope(n: int): seq[codeParts] =
  # echo scopeTable
  # for ident, info in identTable:
  #   echo ident

  # echo "----------------"

  if scopeTable.len()-1 > n:
    var new_scopeTable = initTable[int, seq[string]]()
    for i in 0..n:
      new_scopeTable[i] = scopeTable[i]

    for i in n+1..scopeTable.len()-1:
      for ident in scopeTable[i]:
        if identTable[ident].delete == true:
          result.add((OTHER, "delete"))
          result.add((identTable[ident].Type, ident))
          result.addSemicolon()
        identTable.del(ident)

    scopeTable = new_scopeTable

  # for ident, info in identTable:
  #   echo ident
  # echo scopeTable

# proc searchCodeParts(codePartsList: seq[codeParts], target: string): seq[codeParts] =
#   for cp in codePartsList:
#     if cp.Type == target:
#       result.add(cp)

proc identExistenceCheck(ident: string): bool =
  if identTable.contains(ident):
    if identTable[ident].path <= nesting:
      return true
  
  return false

proc typeMatch(type1: string, type2: string): (bool, string) =
  # echo type1 & "___" & type2

  var
    typeList1: seq[seq[string]]
    typeList2: seq[seq[string]]

  for t1s in type1.split(">>"):
    typeList1.add(@[t1s.split("|")])
  for t2s in type2.split(">>"):
    typeList2.add(@[t2s.split("|")])

  # echo $typeList1 & "________" & $typeList2

  var
    typeFlow: string
    typeCandidacies: seq[string]

  for i, t1ss in typeList1:
    if typeList2.len() <= i:
      return (false, "")
    for t2ss in typeList2[i]:
      for t1sss in t1ss:
        if t1sss == t2ss:
          typeCandidacies.add(t1sss)
    if typeCandidacies != @[]:
      typeFlow.add(typeCandidacies.join("|"))
      typeCandidacies = @[]
    else:
      return (false, "")

  return (true, typeFlow)

proc funcTypeSplit(funcType: string, target: string): (bool, string, string) =
  var fnTs = funcType.split(target)
  if fnTs.len() == 1:
    return (false, "", funcType)

  fnTs[1] = fnTs[1..fnTs.len()-1].join(target)
  
  return (true, fnTs[0], fnTs[1])

proc funcTypesMatch(funcType: string, argType: string): (bool, string, string) =
  var fnTs = funcType.funcTypeSplit(">>")
  let res = typeMatch(fnTs[1], argType)
  
  if fnTs[0] == false or res[0] == false or argType == "":
    return (false, "", fnTs[1])
  
  return (res[0], res[1], fnTs[2])

proc funcTypesMatch(funcType: string, argsType: seq[string]): (bool, string, string) =
  var res: (bool, string, string)
  var passedFuncType: string
  var nextFuncType = funcType
  for argType in argsType:
    res = funcTypesMatch(nextFuncType, argType)
    if res[0]:
      passedFuncType = res[1]
      nextFuncType = res[2]
    else:
      return (false, passedFuncType, nextFuncType)
  
  if nextFuncType.contains(">>"):
    return (false, passedFuncType, nextFuncType)
  else:
    return (true, passedFuncType, nextFuncType)

proc conversionCppType(Type: string): (string, string) =
  let ts = Type.split("::")
  for t in ts:
    case t
    of T_INT:
      return (T_INT, "int")
    of T_FLOAT:
      return (T_FLOAT, "float")
    of T_CHAR:
      return (T_CHAR, "char")
    of T_STRING:
      return (T_STRING, "std::string")
    of T_BOOL:
      return (T_BOOL, "bool")
    of T_ARRAY:
      return (T_ARRAY, "std::vector<" & ts[1..ts.len()-1].join("::").conversionCppType()[1] & ">")
    of T_FUNCTION:
      return (T_FUNCTION, "auto")
    else:
      return (NIL, "NULL")

# 型のチェックをしてC++の演算子に変換する 
proc conversionCppOperator(fn: string, argsType: seq[string]): (bool, string, string) =
  let anything_t = INT & "|" & FLOAT & "|" & CHAR & "|" & STRING & "|" & BOOL
  let number_t = INT & "|" & FLOAT
  var argsTypeC = argsType

  case fn
  of PLUS:
    let fmr1 = funcTypesMatch(number_t & ">>" & number_t & ">>" & number_t, argsTypeC[0])
    if fmr1[0]:
      let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
      return (fmr2[0], fmr2[1], "+")
    else:
      return (false, "", "+")
  of MINUS:
    let fmr1 = funcTypesMatch(number_t & ">>" & number_t & ">>" & number_t, argsTypeC[0])
    if fmr1[0]:
      let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
      return (fmr2[0], fmr2[1], "-")
    else:
      return (false, "", "-")
  of ASTERISC:
    let fmr1 = funcTypesMatch(number_t & ">>" & number_t & ">>" & number_t, argsTypeC[0])
    if fmr1[0]:
      let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
      return (fmr2[0], fmr2[1], "*")
    else:
      return (false, "", "*")
  of SLASH:
    let fmr1 = funcTypesMatch(number_t & ">>" & number_t & ">>" & number_t, argsTypeC[0])
    if fmr1[0]:
      let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
      return (fmr2[0], fmr2[1], "/")
    else:
      return (false, "", "/")
  of LT:
    let fmr1 = funcTypesMatch(anything_t & ">>" & anything_t & ">>" & BOOL, argsTypeC[0])
    if fmr1[0]:
      let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
      return (fmr2[0], BOOL, "<")
    else:
      return (false, "", "<")
  of GT:
    let fmr1 = funcTypesMatch(anything_t & ">>" & anything_t & ">>" & BOOL, argsTypeC[0])
    if fmr1[0]:
      let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
      return (fmr2[0], BOOL, ">")
    else:
      return (false, "", ">")
  of LE:
    let fmr1 = funcTypesMatch(anything_t & ">>" & anything_t & ">>" & BOOL, argsTypeC[0])
    if fmr1[0]:
      let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
      return (fmr2[0], BOOL, "<=")
    else:
      return (false, "", "<=")
  of GE:
    let fmr1 = funcTypesMatch(anything_t & ">>" & anything_t & ">>" & BOOL, argsTypeC[0])
    if fmr1[0]:
      let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
      return (fmr2[0], BOOL, ">=")
    else:
      return (false, "", ">=")
  of EE:
    let fmr1 = funcTypesMatch(anything_t & ">>" & anything_t & ">>" & BOOL, argsTypeC[0])
    if fmr1[0]:
      let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
      return (fmr2[0], BOOL, "==")
    else:
      return (false, "", "==")
  of NE:
    let fmr1 = funcTypesMatch(anything_t & ">>" & anything_t & ">>" & BOOL, argsTypeC[0])
    if fmr1[0]:
      let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
      return (fmr2[0], BOOL, "!=")
    else:
      return (false, "", "!=")

# 型のチェックをしてC++の関数に変換する
proc conversionCppFunction(fn: string, argsType: seq[string]): (bool, string, string) =
  let anything_t = INT & "|" & FLOAT & "|" & CHAR & "|" & STRING & "|" & BOOL
  let number_t = INT & "|" & FLOAT
  let letter_t = CHAR & "|" & STRING
  var argsTypeC = argsType
  # for _ in [argsTypeC.len()-1..2]:
  #   argsTypeC.add("")
  case fn
  of "plus":
    if argsTypeC.len() == 0:
      return (true, IDENT, "ka23::plus")
    elif argsTypeC.len() == 2:
      let fmr1 = funcTypesMatch(number_t & ">>" & number_t & ">>" & number_t, @[argsTypeC[0], argsTypeC[1]])
      if fmr1[0]:
        let res_type = fmr1[1]
        return (fmr1[0], res_type, "ka23::plus")
      else:
        return (false, OTHER, "")
    else:
      return (false, OTHER, "")
  of "minu":
    if argsTypeC.len() == 0:
      return (true, IDENT, "ka23::minu")
    elif argsTypeC.len() == 2:
      # echo (number_t & ">>" & number_t & ">>" & number_t, @[argsTypeC[0], argsTypeC[1]])
      let fmr1 = funcTypesMatch(number_t & ">>" & number_t & ">>" & number_t, @[argsTypeC[0], argsTypeC[1]])
      if fmr1[0]:
        let res_type = fmr1[1]
        return (fmr1[0], res_type, "ka23::minu")
      else:
        return (false, OTHER, "")
    else:
      return (false, OTHER, "")
  of "mult":
    if argsTypeC.len() == 0:
      return (true, IDENT, "ka23::mult")
    elif argsTypeC.len() == 2:
      let fmr1 = funcTypesMatch(number_t & ">>" & number_t & ">>" & number_t, @[argsTypeC[0], argsTypeC[1]])
      if fmr1[0]:
        let res_type = fmr1[1]
        return (fmr1[0], res_type, "ka23::mult")
      else:
        return (false, OTHER, "")
    else:
      return (false, OTHER, "")
  of "divi":
    if argsTypeC.len() == 0:
      return (true, IDENT, "ka23::divi")
    elif argsTypeC.len() == 2:
      let fmr1 = funcTypesMatch(number_t & ">>" & number_t & ">>" & number_t, @[argsTypeC[0], argsTypeC[1]])
      if fmr1[0]:
        let res_type = fmr1[1]
        return (fmr1[0], res_type, "ka23::divi")
      else:
        return (false, OTHER, "")
    else:
      return (false, OTHER, "")
  of "print":
    if argsTypeC.len() == 0:
      return (true, IDENT, "ka23::print")
    elif argsTypeC.len() == 1:
      let fmr1 = funcTypesMatch(letter_t & ">>" & NIL, argsTypeC[0])
      if fmr1[0]:
        let res_type = NIL
        return (fmr1[0], res_type, "ka23::print")
      else:
        return (false, OTHER, "")
    else:
      return (false, OTHER, "")
  of "println":
    if argsTypeC.len() == 0:
      return (true, IDENT, "ka23::println")
    elif argsTypeC.len() == 1:
      let fmr1 = funcTypesMatch(letter_t & ">>" & NIL, argsTypeC[0])
      if fmr1[0]:
        let res_type = NIL
        return (fmr1[0], res_type, "ka23::println")
      else:
        return (false, OTHER, "")
    else:
      return (false, OTHER, "")
  of "len":
    if argsTypeC.len() == 0:
      return (true, IDENT, "ka23::len")
    elif argsTypeC.len() == 1:
      let fmr1 = funcTypesMatch(ARRAY & "::" & anything_t & ">>" & INT, argsTypeC[0])
      if fmr1[0]:
        let res_type = INT
        return (fmr1[0], res_type, "ka23::len")
      else:
        return (false, OTHER, "")
    else:
      return (false, OTHER, "")
  of "join":
    if argsTypeC.len() == 0:
      return (true, IDENT, "ka23::join")
    elif argsTypeC.len() == 2:
      let fmr1 = funcTypesMatch("ARRAY" & "::" & anything_t & ">>" & "ARRAY" & "::" & anything_t & ">>" & "ARRAY" & "::" & anything_t, @[argsTypeC[0], argsTypeC[1]])
      if fmr1[0]:
        let res_type = fmr1[1]
        return (fmr1[0], res_type, "ka23::join")
      else:
        return (false, OTHER, "")
    else:
      return (false, OTHER, "")
  of "head":
    if argsTypeC.len() == 0:
      return (true, IDENT, "ka23::join")
    elif argsTypeC.len() == 1:
      let fmr1 = funcTypesMatch("ARRAY" & "::" & anything_t & ">>" & anything_t, argsTypeC[0])
      if fmr1[0]:
        let res_type = fmr1[1].funcTypeSplit("ARRAY::")[2]
        return (fmr1[0], res_type, "ka23::head")
      else:
        return (false, OTHER, "")
    else:
      return (false, OTHER, "")
  of "tail":
    if argsTypeC.len() == 0:
      return (true, IDENT, "ka23::tail")
    elif argsTypeC.len() == 1:
      let fmr1 = funcTypesMatch("ARRAY" & "::" & anything_t & ">>" & "ARRAY" & "::" & anything_t, argsTypeC[0])
      if fmr1[0]:
        let res_type = fmr1[1]
        return (fmr1[0], res_type, "ka23::tail")
      else:
        return (false, OTHER, "")
    else:
      return (false, OTHER, "")
  of "last":
    if argsTypeC.len() == 0:
      return (true, IDENT, "ka23::last")
    elif argsTypeC.len() == 1:
      let fmr1 = funcTypesMatch("ARRAY" & "::" & anything_t & ">>" & anything_t, argsTypeC[0])
      if fmr1[0]:
        let res_type = fmr1[1].funcTypeSplit("ARRAY::")[2]
        return (fmr1[0], res_type, "ka23::last")
      else:
        return (false, OTHER, "")
    else:
      return (false, OTHER, "")
  of "init":
    if argsTypeC.len() == 0:
      return (true, IDENT, "ka23::init")
    elif argsTypeC.len() == 1:
      let fmr1 = funcTypesMatch("ARRAY" & "::" & anything_t & ">>" & "ARRAY" & "::" & anything_t, argsTypeC[0])
      if fmr1[0]:
        let res_type = fmr1[1]
        return (fmr1[0], res_type, "ka23::init")
      else:
        return (false, OTHER, "")
    else:
      return (false, OTHER, "")
  of "toString":
    if argsTypeC.len() == 0:
      return (true, IDENT, "ka23::toString")
    elif argsTypeC.len() == 1:
      let fmr1 = funcTypesMatch(anything_t & ">>" & anything_t, argsTypeC[0])
      if fmr1[0]:
        let res_type = STRING
        return (fmr1[0], res_type, "ka23::toString")
      else:
        return (false, OTHER, "")
    else:
      return (false, OTHER, "")
  else:
    return (false, NIL, "NULL")

proc replaceSemicolon(parts: seq[codeParts], obj: seq[codeParts]): seq[codeParts] =
  let tail = parts[parts.len()-1]
  if tail.Type[0] == '@':
    return replaceSemicolon(parts[0..parts.len()-2], @[parts[parts.len()-1]] & obj)
  elif tail.Type == SEMICOLON:
    return parts[0..parts.len()-2] & obj
  else:
    return parts

proc addIndent(code: var string, indent: int) =
  if indent != 0:
    for i in 0..indent-1:
      code.add("  ")

# proc addScopeTable(str: string) =
#   if scopeTable.len()-1 == nestCount:
#     scopeTable[nestCount].add(str)
#   elif scopeTable.len()-1 < nestCount:
#     scopeTable.setLen(nestCount)
#     scopeTable.add(@[str])

proc makeCodeParts(node: Node, test: bool): (seq[codeParts], string) =
  var
    code: seq[codeParts]
    codeType: string
  
  case node.kind

  # リテラル
  of nkIntLiteral:
    code.add((INT, node.token.Literal))
    codeType = INT
  of nkFloatLiteral:
    code.add((FLOAT, node.token.Literal & "f"))
    codeType = FLOAT
  of nkBoolLiteral:
    if node.token.Literal == "True":
      code.add((BOOL, "true"))
    else:
      code.add((BOOL, "false"))
    codeType = BOOL
  of nkCharLiteral:
    code.add((CHAR, "\'" & node.token.Literal & "\'"))
    codeType = CHAR
  of nkStringLiteral:
    code.add((STRING, "\"" & node.token.Literal & "\""))
    codeType = STRING
  # 保留
  # of nkCppCode:
  #   if node.cppCodeValue != "":
  #     code.add((CPPCODE, node.cppCodeValue))
  #     code.addSemicolon()
  #     codeType = CPPCODE
  #   else:
  #     echoErrorMessage("型指定の後に名前が書かれていません"3, test)
  #     quit()
  of nkArrayLiteral:
    if node.child_nodes != @[]:
      code.add((LBRACE, "{"))
      var eltype: string
      var loopCount = 0
      for arv in node.child_nodes[0].child_nodes:
        let elem = arv.makeCodeParts(test)
        if loopCount == 0:
          eltype = elem[1]
          code.add(elem[0].replaceSemicolon(@[(OTHER, "")]))
        elif typeMatch(elem[1], eltype)[0]:
          code.add((COMMA, ","))
          code.add(elem[0].replaceSemicolon(@[(OTHER, "")]))
        else:
          echoErrorMessage("配列内の要素の型が全て同じになっていません", test)
        loopCount += 1
      code.add((RBRACE, "}"))
      code.add(("@ARRAYLENGTH", $loopCount))
      codeType = ARRAY & "::" & eltype
    else:
      code.add((LBRACE, "{"))
      code.add((RBRACE, "}"))
      code.add(("@ARRAYLENGTH", "0"))
      codeType = ARRAY
  of nkNIl:
    code.add((NIL, "NULL"))
    codeType = NIL
  of nkIntType:
    if node.child_nodes != @[]:
      code.add(node.token.Type.conversionCppType())
      code.add((INT, node.child_nodes[0].token.Literal))
      codeType = INT
    else:
      echoErrorMessage("型指定の後に名前が書かれていません", test)
  of nkFloatType:
    if node.child_nodes != @[]:
      code.add(node.token.Type.conversionCppType())
      code.add((FLOAT, node.child_nodes[0].token.Literal))
      codeType = FLOAT
    else:
      echoErrorMessage("型指定の後に名前が書かれていません", test)
  of nkCharType:
    if node.child_nodes != @[]:
      code.add(node.token.Type.conversionCppType())
      code.add((CHAR, node.child_nodes[0].token.Literal))
      codeType = CHAR
    else:
      echoErrorMessage("型指定の後に名前が書かれていません", test)
  of nkStringType:
    if node.child_nodes != @[]:
      code.add(node.token.Type.conversionCppType())
      code.add((STRING, node.child_nodes[0].token.Literal))
      codeType = STRING
    else:
      echoErrorMessage("型指定の後に名前が書かれていません", test)
  of nkBoolType:
    if node.child_nodes != @[]:
      code.add(node.token.Type.conversionCppType())
      code.add((BOOL, node.child_nodes[0].token.Literal))
      codeType = BOOL
    else:
      echoErrorMessage("型指定の後に名前が書かれていません", test)
  of nkArrayType:
    if node.child_nodes != @[]:
      code.add(node.token.Type.conversionCppType())
      code.add((node.token.Type, node.child_nodes[0].token.Literal))
      let types = node.token.Type.split("::")
      for i, tv in types:
        if i != 0:
          codeType.add("::")
        codeType.add(tv.removeT())
    else:
      echoErrorMessage("型指定の後に名前が書かれていません", test)
  of nkFunctionType:
    if node.child_nodes != @[]:
      code.add((T_FUNCTION, "auto"))
      code.add((FUNCTION, node.child_nodes[0].token.Literal))
      codeType = FUNCTION
    else:
      echoErrorMessage("型指定の後に名前が書かれていません", test)

  # 名前
  of nkIdent:
    if identExistenceCheck(node.token.Literal):
      if identTable[node.token.Literal].delete:
        code.add((OTHER, "*"))
        code.add((IDENT, node.token.Literal))
        codeType = identTable[node.token.Literal].Type
      else:
        code.add((IDENT, node.token.Literal))
        codeType = identTable[node.token.Literal].Type
    else:
      let ic = node.token.Literal.conversionCppFunction(@[])
      if ic[1] == NIL:
        echoErrorMessage("定義されていない名前", test)
      code.add((ic[1], ic[2]))
      codeType = ic[1]

  # 【】
  # of nkMapFunction:
  #   code.add((IDENT, "ka23::map"))
  #   codeType = IDENT
  
  # 
  
  # let文
  of nkLetStatement:
    let li = node.child_nodes[0].makeCodeParts(test)
    let lv = node.child_nodes[1].makeCodeParts(test)
    echo li
    # echo li[1] & "___" & lv[1]
    if li[1] == lv[1]:
      if identExistenceCheck(li[0][1][1]):
        code.add((OTHER, "delete"))
        code.add(li[0][1])
        code.addSemicolon()
      code.add(li[0][0])
      code.add((OTHER, "*"))
      code.add(li[0][1])
      code.add((OTHER, "="))
      code.add((OTHER, "new"))
      code.add(li[0][0])
      code.addSemicolon()
      code.add((OTHER, "*"))
      code.add(li[0][1])
      code.add((OTHER, "="))
      code.add(lv[0].replaceSemicolon(@[(OTHER, "")]))
      code.addSemicolon()
      identTable[li[0][1][1]] = IdentInfo(
        Type:     li[1],
        contents: lv[0],
        path:     nesting,
        mutable:  false,
        delete:   true,
      )
      addScopeTable(li[0][1][1], nesting)
    else:
      echoErrorMessage("指定している型と値の型が違います", test)
  
  # var文
  of nkVarStatement:
    let li = node.child_nodes[0].makeCodeParts(test)
    let lv = node.child_nodes[1].makeCodeParts(test)
    if li[1] == lv[1]:
      if identExistenceCheck(li[0][1][1]):
        echoErrorMessage("既に定義されています", test)
      code.add(li[0])
      code.add((OTHER, "="))
      code.add(lv[0])
      code.addSemicolon()
      identTable[li[0][1][1]] = IdentInfo(
        Type:     li[1],
        contents: lv[0],
        path:     nesting,
        mutable:  true,
        delete:   false,
      )
      addScopeTable(li[0][1][1], nesting)
    else:
      echoErrorMessage("指定している型と値の型が違います", test)

  # def文
  of nkDefineStatement:
    let di = node.child_nodes[0].makeCodeParts(test)
    if identExistenceCheck(di[0][1][1]):
      echoErrorMessage("既に定義されています", test)
    # echo di
    code.add((OTHER, di[0][0].Code))
    code.add(di[0][1])
    if node.child_nodes[1].child_nodes == @[]:
      identTable[di[0][1][1]] = IdentInfo(
        Type:    NIL & ">>" & di[1],
        path:    nesting,
        mutable: false,
        delete:  false,
      )
      addScopeTable(di[0][1][1], nesting)
    else:
      var argsType: seq[string]
      for parameter in node.child_nodes[1].child_nodes:
        argsType.add(parameter.token.Type.removeT())
      identTable[di[0][1][1]] = IdentInfo(
        Type:    argsType.join(">>") & ">>" & di[1],
        path:    nesting,
        mutable: false,
        delete:  false,
      )
      addScopeTable(di[0][1][1], nesting)
    var origin = nesting
    nesting = nesting + 1
    if node.child_nodes[1].child_nodes == @[]:
      code.add((OTHER, "()"))
      code.add((OTHER, "{"))
      for statement in node.child_nodes[2].child_nodes:
        if statement.kind == nkReturnStatement:
          let st = statement.makeCodeParts(test)
          if typeMatch(st[1], di[1])[0]:
            code.add(st[0])
          else:
            echoErrorMessage("指定している型と返り値の型が違います", test)
        else:
          code.add(statement.makeCodeParts(test)[0])
    else:
      code.add((OTHER, "("))
      for i, parameter in node.child_nodes[1].child_nodes:
        if i != 0:
          code.add((OTHER, ","))
        let pr = parameter.makeCodeParts(test)
        code.add(pr[0])
        identTable[parameter.child_nodes[0].token.Literal] = IdentInfo(
          Type:    pr[1],
          path:    nesting,
          mutable: false,
          delete:  false,
        )
        addScopeTable(parameter.child_nodes[0].token.Literal, nesting)
      code.add((OTHER, ")"))
      code.add((OTHER, "{"))
      for statement in node.child_nodes[2].child_nodes:
        if statement.kind == nkReturnStatement:
          let st = statement.makeCodeParts(test)
          if typeMatch(st[1], di[1])[0]:
            code.add(st[0])
          else:
            echoErrorMessage("指定している型と返り値の型が違います", test)
        else:
          code.add(statement.makeCodeParts(test)[0])
    # nestingをリセット
    nesting = origin
    code.add(deleteScope(nesting))
    code.add((OTHER, "}"))
    code.add((OTHER, "\n"))
    codeType = DEFINE

  # return文
  of nkReturnStatement:
    if node.child_nodes != @[]:
      code.add((OTHER, "return"))
      code.add((OTHER, "("))
      let r = node.child_nodes[0].makeCodeParts(test)
      code.add(r[0].replaceSemicolon(@[(OTHER, "")]))
      code.add((OTHER, ")"))
      code.addSemicolon()
      codeType = r[1]
    else:
      echoErrorMessage("式がありません", test)
  
  # 中置
  of nkInfixExpression:
    var 
      l: (seq[codeParts], string)
      r: (seq[codeParts], string)
    if node.child_nodes.len() != 2:
      echoErrorMessage("オペランドがありません", test)
    l = node.child_nodes[0].makeCodeParts(test)
    r = node.child_nodes[1].makeCodeParts(test)
    if l[1] == r[1]:
      let oc = node.token.Literal.conversionCppOperator(@[l[1], r[1]])
      if oc[0] == false:
        echoErrorMessage("オペランドの型が間違っています", test)
      code.add(((OTHER, "(")))
      code.add(l[0].replaceSemicolon(@[(OTHER, "")]))
      code.add((node.token.Type, oc[2]))
      code.add(r[0].replaceSemicolon(@[(OTHER, "")]))
      code.add(((OTHER, ")")))
      code.addSemicolon()
      codeType = oc[1]
    else:
      echoErrorMessage("オペランドの型がそれぞれ違います", test)
  
  # Generator
  of nkGenerator:
    # TODO: 型のチェック
    var lt: string
    if node.child_nodes.len() == 2:
      let l = node.child_nodes[0].makeCodeParts(test)
      code.add(l[0])
      lt = l[1]
      nesting = nesting + 1
      if identExistenceCheck(l[0][1][1]):
        echoErrorMessage("既に定義されています", test)
      identTable[l[0][1][1]] = IdentInfo(
        Type:    lt,
        path:    nesting,
        mutable: false,
        delete:  false,
      )
      codeType = l[1]
      
      code.add((COLON, ":"))

      let r = node.child_nodes[1].makeCodeParts(test)
      if lt == r[1].funcTypeSplit("ARRAY::")[2]:
        code.add(r[0])
      else:
        echoErrorMessage("指定している型と値の型が違います", test)
    else:
      echoErrorMessage("式がありません", test)

  # パイプライン演算子
  of nkPipeExpression:
    echoErrorMessage("対象が関数ではありません", test)

  # 配列の要素へのアクセス
  of nkAccessElement:
    if node.child_nodes.len() == 2:
      let l = node.child_nodes[0].makeCodeParts(test)
      let r = node.child_nodes[1].makeCodeParts(test)
      let rv = r[0].replaceSemicolon(@[(OTHER, "")])
      let ls = l[1].split("::")
      # TODO 元最悪
      if r[1] == INT and l[0][0].Type == IDENT and ls[0] == ARRAY:
        code.add(l[0].replaceSemicolon(@[(OTHER, "")]))
        code.add((OTHER, "["))
        code.add(rv)
        code.add((OTHER, "]"))
        code.addSemicolon()
        codeType = ls[1..ls.len()-1].join("::")
      else:
        echoErrorMessage("オペランドの型が間違っています", test)
    else:
      echoErrorMessage("オペランドがありません", test)

  # 代入式
  of nkAssignExpression:
    var lt, rt: string
    var lmc: string
    if node.child_nodes.len() == 2:
      # 値を代入しようとしている変数のチェック
      let l = node.child_nodes[0].makeCodeParts(test)
      lmc = l[0][l[0].len()-1].Code
      if lmc == ";":
        lmc = l[0][l[0].len()-2].Code
      if identExistenceCheck(lmc):
        if identTable[lmc].mutable == false:
          echoErrorMessage("代入しようとしている変数がイミュータブルです", test)
      else:
        echoErrorMessage("定義されていない名前です", test)
      code.add(l[0].replaceSemicolon(@[(OTHER, "")]))
      lt = l[1]

      code.add((OTHER, "="))
      let r = node.child_nodes[1].makeCodeParts(test)
      code.add(r[0])
      identTable[lmc].contents = r[0]
      rt = r[1]
    else:
      echoErrorMessage("オペランドがありません", test)
    code.addSemicolon()
    if typeMatch(lt, rt)[0]:
      codeType = lt
    else:
      echoErrorMessage("オペランドの型がそれぞれ違います", test)

  # 前置
  # TODO 
  of nkCallExpression:
    # 保留
    # if node.function.kind == nkMapFunction:
    #   code.add((OTHER, "("))
    #   var at: string
    #   for i, arg in node.args:
    #     let a = arg.makeCodeParts(test)
    #     if i != 0:
    #       code.add((OTHER, ","))
    #       at = a[1]
    #     code.add(a[0].replaceSemicolon(@[(OTHER, "")]))
    #   code.add((OTHER, ")"))
    #   code.addSemicolon()
    #   codeType = ARRAY & "::" & at.funcTypeSplit(">>")[2]
    #   echo codeType
    var argsCode: seq[seq[codeParts]]
    var argsType: seq[string]
    
    for i, arg in node.child_nodes[1].child_nodes:
      let a = arg.makeCodeParts(test)
      argsCode.add(a[0].replaceSemicolon(@[(OTHER, "")]))
      argsType.add(a[1])
    # TODO
    let funcName = node.child_nodes[0].token.Literal
    let iec = identExistenceCheck(funcName)
    if iec:
      let ftm = funcTypesMatch(identTable[funcName].Type, argsType)
      if ftm[0]:
        code.add((IDENT, funcName))
        codeType = ftm[2]
      else:
        echoErrorMessage("引数の型が正しくありません", test)
    else:
      let ccf = conversionCppFunction(funcName, argsType)
      if ccf[0]:
        code.add((IDENT, ccf[2]))
        codeType = ccf[1]
      else:
        if ccf[1] == OTHER:
          echoErrorMessage("引数の型が正しくありません", test)
        else:
          echoErrorMessage("定義されていない名前です", test)
    
    code.add((OTHER, "("))
    for i, argc in argsCode:
      if i != 0:
        code.add((OTHER, ","))
      code.add(argc)
    code.add((OTHER, ")"))
    code.addSemicolon()
    # else:
      # 特殊
      # case fm[2]
      # of "ka23::join":
      #   let ats = argsCode.searchCodeParts("@ARRAYLENGTH")
      #   echo argsCode
      #   if ats.len() >= 2:
      #     # 元最悪
      #     code.add(("@ARRAYLENGTH", $(ats[ats.len()-1].Code.parseInt() + ats[ats.len()-2].Code.parseInt())))
      # of "ka23::head":
        
      #   if ats[ats.len()-1].Code.parseInt() == 0:
      #     echoErrorMessage("型指定の後に名前が書かれていません"5, test)
      

  # if文
  of nkIfStatement:
    code.add((OTHER, "if"))
    code.add((OTHER, "("))
    code.add(node.child_nodes[0].makeCodeParts(test)[0].replaceSemicolon(@[(OTHER, "")]))
    code.add((OTHER, ")"))
    code.add((OTHER, "{"))
    var sr: (seq[codeParts], string)
    for i, statement in node.child_nodes[1].child_nodes:
      if i == node.child_nodes[1].child_nodes.len()-1:
        sr = statement.makeCodeParts(test)
        code.add(sr[0])
      else:
        sr = statement.makeCodeParts(test)
        code.add(sr[0])
    code.add((OTHER, "}"))
    if node.child_nodes.len() == 3:
      let ar = node.child_nodes[2].makeCodeParts(test)
      code.add(ar[0])
    else:
      code.add((OTHER, "\n"))
    codeType = sr[1]

  # elif文
  of nkElifStatement:
    code.add((OTHER, "else if"))
    code.add((OTHER, "("))
    code.add(node.child_nodes[0].makeCodeParts(test)[0].replaceSemicolon(@[(OTHER, "")]))
    code.add((OTHER, ")"))
    code.add((OTHER, "{"))
    var sr: (seq[codeParts], string)
    for i, statement in node.child_nodes[1].child_nodes:
      if i == node.child_nodes[1].child_nodes.len()-1:
        sr = statement.makeCodeParts(test)
        code.add(sr[0])
      else:
        sr = statement.makeCodeParts(test)
        code.add(sr[0])
    code.add((OTHER, "}"))
    if node.child_nodes.len() == 3:
      let ar = node.child_nodes[2].makeCodeParts(test)
      code.add(ar[0])
    else:
      code.add((OTHER, "\n"))
    codeType = sr[1]

  # else文
  of nkElseStatement:
    code.add((OTHER, "else"))
    code.add((OTHER, "{"))
    var sr: (seq[codeParts], string)
    for i, statement in node.child_nodes[0].child_nodes:
      if i == node.child_nodes[0].child_nodes.len()-1:
        sr = statement.makeCodeParts(test)
        code.add(sr[0])
      else:
        sr = statement.makeCodeParts(test)
        code.add(sr[0])
    code.add((OTHER, "}"))
    code.add((OTHER, "\n"))
    codeType = sr[1]
  
  # if式
  of nkIfExpression:
    code.add((OTHER, "("))
    code.add(node.child_nodes[0].makeCodeParts(test)[0].replaceSemicolon(@[(OTHER, "")]))
    code.add((OTHER, "?"))
    var sr = node.child_nodes[1].makeCodeParts(test)
    code.add(sr[0].replaceSemicolon(@[(OTHER, "")]))
    let ar = node.child_nodes[2].makeCodeParts(test)
    if typeMatch(ar[1], sr[1])[0]:
      code.add((OTHER, ":"))
      code.add(ar[0].replaceSemicolon(@[(OTHER, "")]))
      codeType = sr[1]
      code.add((OTHER, ")"))
      code.addSemicolon()
    else:
      echoErrorMessage("返り値の型が異なっています", test)

  # else式
  of nkElseExpression:
    var sr = node.child_nodes[0].makeCodeParts(test)
    code.add(sr[0].replaceSemicolon(@[(OTHER, "")]))
    codeType = sr[1]

  # for文
  # TODO
  of nkForStatement:
    let origin = nesting
    code.add((OTHER, "for"))
    code.add((OTHER, "("))
    code.add(node.child_nodes[0].makeCodeParts(test)[0])
    code.add((OTHER, ")"))
    code.add((OTHER, "{"))
    var sr: (seq[codeParts], string)
    for i, statement in node.child_nodes[1].child_nodes:
      sr = statement.makeCodeParts(test)
      code.add(sr[0])
    nesting = origin
    code.add(deleteScope(nesting))
    code.add((OTHER, "}"))
    code.add((OTHER, "\n"))
    codeType = sr[1]
  else:
    return (code, codeType)
  
  return (code, codeType)

proc makeCppCode*(node: Node, indent: int, test: bool): string =
  var parts: (seq[codeParts], string)
  for child in node.child_nodes:
    parts[0].add(makeCodeParts(child, test)[0])
  var outCode: seq[string]
  var newLine: string
  var braceCount: int = indent
  
  for d in deleteScope(-1):
    parts[0].add(d)
    # echo d

  for i, part in parts[0]:
    # echo $i & "回目 : " & part
    # echo part
    if part.Type[0] == '@' or part.Code == "":
      continue
    if part.Type == SEMICOLON and part.Code == ";":
      newLine.add(part.Code)
      var ind = ""
      ind.addIndent(braceCount)
      outCode.add(ind & newLine & "\n")
      newLine = ""
    elif part.Type == OTHER and part.Code == "{":
      newLine.add(part.Code)
      var ind = ""
      ind.addIndent(braceCount)
      if outCode.len() == 0:
        outCode.add(ind & newLine & "\n")
      else:
        outCode.add("\n" & ind & newLine & "\n")
      braceCount = braceCount + 1
      newLine = ""
    elif part.Type == OTHER and part.Code == "}":
      if newLine.split(" ").join("") != "":
        outCode.add(newLine)
      braceCount = braceCount - 1
      newLine = ""
      newLine.addIndent(braceCount)
      newLine.add(part.Code)
      outCode.add(newLine)
      newLine = ""
    elif part.Type == OTHER and part.Code == "\n":
      newLine.add(part.Code)
    else:
      newLine.add(part.Code & " ")
    
  outCode.add(newLine)
  
  return outCode.join()