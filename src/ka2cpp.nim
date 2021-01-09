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
  used*:        bool

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
  var rts: seq[string]
  for ts in Type.split("::"):
    if ts[0] == 'T' and ts[1] == '_':
      rts.add(ts[2..ts.len()-1])
    else:
      rts.add(ts)

  return rts.join("::")

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
  
proc deleteScope(n: int, test: bool): seq[codeParts] =
  if scopeTable.len()-1 > n:
    var new_scopeTable = initTable[int, seq[string]]()
    for i in 0..n:
      new_scopeTable[i] = scopeTable[i]

    for i in n+1..scopeTable.len()-1:
      for ident in scopeTable[i]:
        # if identTable[ident].mutable == true:
        #   if identTable[ident].used == true:
        #     result.add((OTHER, "delete"))
        #     result.add((identTable[ident].Type, ident))
        #     result.addSemicolon()
        #   else:
        #     echoErrorMessage("定義された一時変数が一度も使用されていません", test, node.token.Line)
        identTable.del(ident)

    scopeTable = new_scopeTable

proc identExistenceCheck(ident: string): bool =
  if identTable.contains(ident):
    if identTable[ident].path <= nesting:
      return true
  
  return false

proc arrayingTypes(types: string): seq[seq[string]] =
  var
    add_type = ""
    bracket_count = 0
    array1: seq[string]
    string1: string

  for t1s in types.split("+"):
    for t1ss in t1s.split("|"):
      add_type = t1ss
      if add_type.contains("["):
        bracket_count = bracket_count + 1
        add_type = t1ss.split("[")[1]
      if add_type.contains("]"):
        bracket_count = bracket_count - 1
        add_type = t1ss.split("[")[0]
      
      if bracket_count != 0:
        for _ in @[0..bracket_count]:
          string1.add("ARRAY::")
      array1.add(string1 & add_type)
      string1 = ""
    result.add(array1)

proc typeMatch(type1: string, type2: string): (bool, string) =
  var
    typeArray1: seq[seq[string]] = arrayingTypes(type1)
    typeArray2: seq[seq[string]] = arrayingTypes(type2)

  var
    typeFlow: seq[string]
    typeCandidacies: seq[string]

  if typeArray1.len() != typeArray2.len():
    return (false, "")

  for i, t1ss in typeArray1:
    for t2ss in typeArray2[i]:
      for t1sss in t1ss:
        if t1sss == t2ss:
          typeCandidacies.add(t1sss)
    if typeCandidacies != @[]:
      typeFlow.add(typeCandidacies.join("|"))
      typeCandidacies = @[]
    else:
      return (false, "")

  return (true, typeFlow.join("+"))

proc funcTypeSplit(funcType: string, target: string): (bool, string, string) =
  var fnTs = funcType.split(target)
  if fnTs.len() == 1:
    return (false, "", funcType)

  fnTs[1] = fnTs[1..fnTs.len()-1].join(target)
  
  return (true, fnTs[0], fnTs[1])

# [0] -> マッチしたかどうか [1] -> マッチした型 [2] -> 返り値の型
proc funcTypesMatch(funcType: string, argType: string): (bool, string, string) =
  var (_, flow, res) = funcType.funcTypeSplit("->")
  var match = typeMatch(flow, argType)
  
  return (match[0], match[1], res)

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
  
  if nextFuncType.contains("+"):
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
      return (T_ARRAY & "::" & ts[1..ts.len()-1].join("::").conversionCppType()[0], "std::vector<" & ts[1..ts.len()-1].join("::").conversionCppType()[1] & ">")
    of T_FUNCTION:
      return (T_FUNCTION, "auto")
    else:
      return (NIL, "NULL")

# 型のチェックをしてC++の演算子に変換する 
proc conversionCppOperator(fn: string, argsType: seq[string]): (bool, string, string) =
  let anything_t = INT & "|" & FLOAT & "|" & CHAR & "|" & STRING & "|" & BOOL
  let number_t = INT & "|" & FLOAT

  case fn
  of PLUS:
    let fmr1 = funcTypesMatch(number_t & "+" & number_t & "->" & number_t, argsType.join("+"))
    let res_type = fmr1[1].split("+")[0]
    return (fmr1[0], res_type, "+")
  of MINUS:
    let fmr1 = funcTypesMatch(number_t & "+" & number_t & "->" & number_t, argsType.join("+"))
    let res_type = fmr1[1].split("+")[0]
    return (fmr1[0], res_type, "-")
  of ASTERISC:
    let fmr1 = funcTypesMatch(number_t & "+" & number_t & "->" & number_t, argsType.join("+"))
    let res_type = fmr1[1].split("+")[0]
    return (fmr1[0], res_type, "*")
  of SLASH:
    let fmr1 = funcTypesMatch(number_t & "+" & number_t & "->" & number_t, argsType.join("+"))
    let res_type = fmr1[1].split("+")[0]
    return (fmr1[0], res_type, "/")
  of LT:
    let fmr1 = funcTypesMatch(anything_t & "+" & anything_t & "->" & BOOL, argsType.join("+"))
    let res_type = BOOL
    return (fmr1[0], res_type, "<")
  of GT:
    let fmr1 = funcTypesMatch(anything_t & "+" & anything_t & "->" & BOOL, argsType.join("+"))
    let res_type = BOOL
    return (fmr1[0], res_type, ">")
  of LE:
    let fmr1 = funcTypesMatch(anything_t & "+" & anything_t & "->" & BOOL, argsType.join("+"))
    let res_type = BOOL
    return (fmr1[0], res_type, "<=")
  of GE:
    let fmr1 = funcTypesMatch(anything_t & "+" & anything_t & "->" & BOOL, argsType.join("+"))
    let res_type = BOOL
    return (fmr1[0], res_type, ">=")
  of EE:
    let fmr1 = funcTypesMatch(anything_t & "+" & anything_t & "->" & BOOL, argsType.join("+"))
    let res_type = BOOL
    return (fmr1[0], res_type, "==")
  of NE:
    let fmr1 = funcTypesMatch(anything_t & "+" & anything_t & "->" & BOOL, argsType.join("+"))
    let res_type = BOOL
    return (fmr1[0], res_type, "!=")

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
      let fmr1 = funcTypesMatch(number_t & "+" & number_t & "->" & number_t, argsType.join("+"))
      if fmr1[0]:
        let res_type = fmr1[1].split("+")[0]
        return (fmr1[0], res_type, "ka23::plus")
      else:
        return (false, OTHER, "")
    else:
      return (false, OTHER, "")
  of "minu":
    if argsTypeC.len() == 0:
      return (true, IDENT, "ka23::minu")
    elif argsTypeC.len() == 2:
      let fmr1 = funcTypesMatch(number_t & "+" & number_t & "->" & number_t, argsType.join("+"))
      if fmr1[0]:
        let res_type = fmr1[1].split("+")[0]
        return (fmr1[0], res_type, "ka23::minu")
      else:
        return (false, OTHER, "")
    else:
      return (false, OTHER, "")
  of "mult":
    if argsTypeC.len() == 0:
      return (true, IDENT, "ka23::mult")
    elif argsTypeC.len() == 2:
      let fmr1 = funcTypesMatch(number_t & "+" & number_t & "->" & number_t, argsType.join("+"))
      if fmr1[0]:
        let res_type = fmr1[1].split("+")[0]
        return (fmr1[0], res_type, "ka23::mult")
      else:
        return (false, OTHER, "")
    else:
      return (false, OTHER, "")
  of "divi":
    if argsTypeC.len() == 0:
      return (true, IDENT, "ka23::divi")
    elif argsTypeC.len() == 2:
      let fmr1 = funcTypesMatch(number_t & "+" & number_t & "->" & number_t, argsType.join("+"))
      if fmr1[0]:
        let res_type = fmr1[1].split("+")[0]
        return (fmr1[0], res_type, "ka23::divi")
      else:
        return (false, OTHER, "")
    else:
      return (false, OTHER, "")
  of "print":
    if argsTypeC.len() == 0:
      return (true, IDENT, "ka23::print")
    elif argsTypeC.len() == 1:
      let fmr1 = funcTypesMatch(letter_t & "->" & NIL, argsType.join("+"))
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
      let fmr1 = funcTypesMatch(letter_t & "->" & NIL, argsType.join("+"))
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
      let fmr1 = funcTypesMatch(ARRAY & "[" & anything_t & "]" & "->" & INT, argsType.join("+"))
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
      let fmr1 = funcTypesMatch("ARRAY" & "[" & anything_t & "]" & "+" & "ARRAY" & "[" & anything_t & "]" & "->" & "ARRAY" & "[" & anything_t & "]", argsType.join("+"))
      if fmr1[0]:
        let res_type = fmr1[1].split("+")[0]
        return (fmr1[0], res_type, "ka23::join")
      else:
        return (false, OTHER, "")
    else:
      return (false, OTHER, "")
  of "head":
    if argsTypeC.len() == 0:
      return (true, IDENT, "ka23::join")
    elif argsTypeC.len() == 1:
      let fmr1 = funcTypesMatch("ARRAY" & "[" & anything_t & "]" & "->" & anything_t, argsType.join("+"))
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
      let fmr1 = funcTypesMatch("ARRAY" & "[" & anything_t & "]" & "->" & "ARRAY" & "::" & anything_t, argsType.join("+"))
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
      let fmr1 = funcTypesMatch("ARRAY" & "[" & anything_t & "]" & "->" & anything_t, argsType.join("+"))
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
      let fmr1 = funcTypesMatch("ARRAY" & "[" & anything_t & "]" & "->" & "ARRAY" & "::" & anything_t, argsType.join("+"))
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
      let fmr1 = funcTypesMatch(anything_t & "->" & anything_t, argsType.join("+"))
      if fmr1[0]:
        let res_type = STRING
        return (fmr1[0], res_type, "ka23::toString")
      else:
        return (false, OTHER, "")
    else:
      return (false, OTHER, "")
  of "at":
    if argsTypeC.len() == 0:
      return (true, IDENT, "ka23::at")
    elif argsTypeC.len() == 2:
      let fmr1 = funcTypesMatch("ARRAY" & "[" & anything_t & "]" & "+" & number_t & "->" & anything_t, argsType.join("+"))
      if fmr1[0]:
        let res_type = fmr1[1].split("+")[0]
        return (fmr1[0], res_type, "ka23::at")
      else:
        return (false, OTHER, "")
    else:
      return (false, OTHER, "")
  of "readln":
    if argsTypeC.len() == 0:
      let res_type = STRING
      return (true, res_type, "ka23::readln")
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

proc makeCodeParts(node: Node, test: bool, dost: bool): (seq[codeParts], string) =
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
  of nkArrayLiteral:
    if node.child_nodes != @[]:
      code.add((LBRACE, "{"))
      var eltype: string
      var loopCount = 0
      for arv in node.child_nodes[0].child_nodes:
        let elem = arv.makeCodeParts(test, dost)
        if loopCount == 0:
          eltype = elem[1]
          code.add(elem[0].replaceSemicolon(@[(OTHER, "")]))
        elif typeMatch(elem[1], eltype)[0]:
          code.add((COMMA, ","))
          code.add(elem[0].replaceSemicolon(@[(OTHER, "")]))
        else:
          echoErrorMessage("配列内の要素の型が全て同じになっていません", test, node.token.Line)
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
    if node.child_nodes.len() == 1:
      var type_name = node.token.Type.conversionCppType()
      code.add(type_name)
      code.add((INT, node.child_nodes[0].token.Literal))
      codeType = type_name[0].removeT()
    elif node.child_nodes.len() == 2:
      var type_name = node.token.Type.conversionCppType()
      var var_name = node.child_nodes[0].token.Literal
      var value = node.child_nodes[1].makeCodeParts(test, dost)
      if type_name[0].removeT() == value[1]:
        if identExistenceCheck(var_name):
          echoErrorMessage("既に定義されています", test, node.token.Line)
        code.add((OTHER, "const"))
        code.add(type_name)
        code.add((INT, var_name))
        code.add((OTHER, "="))
        code.add(value[0])
        code.addSemicolon()
        identTable[var_name] = IdentInfo(
          Type:     type_name[0].removeT(),
          contents: value[0],
          path:     nesting,
          mutable:  false,
          used:     false,
        )
        addScopeTable(var_name, nesting)
        codeType = type_name[0].removeT()
      else:
        echoErrorMessage("指定している型と値の型が違います", test, node.token.Line)
    else:
      echoErrorMessage("不明なエラー", test, node.token.Line)
  of nkFloatType:
    if node.child_nodes.len() == 1:
      var type_name = node.token.Type.conversionCppType()
      code.add(type_name)
      code.add((FLOAT, node.child_nodes[0].token.Literal))
      codeType = type_name[0].removeT()
    elif node.child_nodes.len() == 2:
      var type_name = node.token.Type.conversionCppType()
      var var_name = node.child_nodes[0].token.Literal
      var value = node.child_nodes[1].makeCodeParts(test, dost)
      if type_name[0].removeT() == value[1]:
        if identExistenceCheck(var_name):
          echoErrorMessage("既に定義されています", test, node.token.Line)
        code.add((OTHER, "const"))
        code.add(type_name)
        code.add((FLOAT, var_name))
        code.add((OTHER, "="))
        code.add(value[0])
        code.addSemicolon()
        identTable[var_name] = IdentInfo(
          Type:     type_name[0].removeT(),
          contents: value[0],
          path:     nesting,
          mutable:  false,
          used:     false,
        )
        addScopeTable(var_name, nesting)
        codeType = type_name[0].removeT()
      else:
        echoErrorMessage("指定している型と値の型が違います", test, node.token.Line)
    else:
      echoErrorMessage("不明なエラー", test, node.token.Line)
  of nkCharType:
    if node.child_nodes.len() == 1:
      var type_name = node.token.Type.conversionCppType()
      code.add(type_name)
      code.add((CHAR, node.child_nodes[0].token.Literal))
      codeType = type_name[0].removeT()
    elif node.child_nodes.len() == 2:
      var type_name = node.token.Type.conversionCppType()
      var var_name = node.child_nodes[0].token.Literal
      var value = node.child_nodes[1].makeCodeParts(test, dost)
      if type_name[0].removeT() == value[1]:
        if identExistenceCheck(var_name):
          echoErrorMessage("既に定義されています", test, node.token.Line)
        code.add((OTHER, "const"))
        code.add(type_name)
        code.add((CHAR, var_name))
        code.add((OTHER, "="))
        code.add(value[0])
        code.addSemicolon()
        identTable[var_name] = IdentInfo(
          Type:     type_name[0].removeT(),
          contents: value[0],
          path:     nesting,
          mutable:  false,
          used:     false,
        )
        addScopeTable(var_name, nesting)
        codeType = type_name[0].removeT()
      else:
        echoErrorMessage("指定している型と値の型が違います", test, node.token.Line)
    else:
      echoErrorMessage("不明なエラー", test, node.token.Line)
  of nkStringType:
    if node.child_nodes.len() == 1:
      var type_name = node.token.Type.conversionCppType()
      code.add(type_name)
      code.add((STRING, node.child_nodes[0].token.Literal))
      codeType = type_name[0].removeT()
    elif node.child_nodes.len() == 2:
      var type_name = node.token.Type.conversionCppType()
      var var_name = node.child_nodes[0].token.Literal
      var value = node.child_nodes[1].makeCodeParts(test, dost)
      if type_name[0].removeT() == value[1]:
        if identExistenceCheck(var_name):
          echoErrorMessage("既に定義されています", test, node.token.Line)
        code.add((OTHER, "const"))
        code.add(type_name)
        code.add((STRING, var_name))
        code.add((OTHER, "="))
        code.add(value[0])
        code.addSemicolon()
        identTable[var_name] = IdentInfo(
          Type:     type_name[0].removeT(),
          contents: value[0],
          path:     nesting,
          mutable:  false,
          used:     false,
        )
        addScopeTable(var_name, nesting)
        codeType = type_name[0].removeT()
      else:
        echoErrorMessage("指定している型と値の型が違います", test, node.token.Line)
    else:
      echoErrorMessage("不明なエラー", test, node.token.Line)
  of nkBoolType:
    if node.child_nodes.len() == 1:
      var type_name = node.token.Type.conversionCppType()
      code.add(type_name)
      code.add((BOOL, node.child_nodes[0].token.Literal))
      codeType = type_name[0].removeT()
    elif node.child_nodes.len() == 2:
      var type_name = node.token.Type.conversionCppType()
      var var_name = node.child_nodes[0].token.Literal
      var value = node.child_nodes[1].makeCodeParts(test, dost)
      if type_name[0].removeT() == value[1]:
        if identExistenceCheck(var_name):
          echoErrorMessage("既に定義されています", test, node.token.Line)
        code.add((OTHER, "const"))
        code.add(type_name)
        code.add((BOOL, var_name))
        code.add((OTHER, "="))
        code.add(value[0])
        code.addSemicolon()
        identTable[var_name] = IdentInfo(
          Type:     type_name[0].removeT(),
          contents: value[0],
          path:     nesting,
          mutable:  false,
          used:     false,
        )
        addScopeTable(var_name, nesting)
        codeType = type_name[0].removeT()
      else:
        echoErrorMessage("指定している型と値の型が違います", test, node.token.Line)
    else:
      echoErrorMessage("不明なエラー", test, node.token.Line)
  of nkArrayType:
    if node.child_nodes.len() == 1:
      # ARRAYだけ特殊
      code.add(node.token.Type.conversionCppType())
      code.add((ARRAY, node.child_nodes[0].token.Literal))
      let types = node.token.Type.split("::")
      for i, tv in types:
        if i != 0:
          codeType.add("::")
        codeType.add(tv.removeT())
    elif node.child_nodes.len() == 2:
      var type_name = node.token.Type.conversionCppType()
      var var_name = node.child_nodes[0].token.Literal
      var value = node.child_nodes[1].makeCodeParts(test, dost)
      if type_name[0].removeT() == value[1]:
        if identExistenceCheck(var_name):
          echoErrorMessage("既に定義されています", test, node.token.Line)
        # ARRAYだけ特殊
        let types = node.token.Type.split("::")
        for i, tv in types:
          if i != 0:
            codeType.add("::")
          codeType.add(tv.removeT())
        code.add((OTHER, "const"))
        code.add(type_name)
        code.add((FLOAT, var_name))
        code.add((OTHER, "="))
        code.add(value[0])
        code.addSemicolon()
        identTable[var_name] = IdentInfo(
          Type:     codeType,
          contents: value[0],
          path:     nesting,
          mutable:  false,
          used:     false,
        )
        addScopeTable(var_name, nesting)
      else:
        echoErrorMessage("指定している型と値の型が違います", test, node.token.Line)
    else:
      echoErrorMessage("不明なエラー", test, node.token.Line)

  # コメント
  of nkComment:
    codeType = COMMENTBEGIN

  # 名前
  of nkIdent:
    if identExistenceCheck(node.token.Literal):
      if identTable[node.token.Literal].mutable:
        code.add((OTHER, "*"))
        code.add((IDENT, node.token.Literal))
        codeType = identTable[node.token.Literal].Type
        identTable[node.token.Literal].used = true
      else:
        code.add((IDENT, node.token.Literal))
        codeType = identTable[node.token.Literal].Type
    else:
      let ic = node.token.Literal.conversionCppFunction(@[])
      if ic[1] == NIL:
        echoErrorMessage("定義されていない名前", test, node.token.Line)
      code.add((ic[1], ic[2]))
      codeType = ic[1]
  
  # let文
  # of nkLetStatement:
  #   if node.child_nodes.len() == 2:
  #     let li = node.child_nodes[0].makeCodeParts(test, dost)
  #     let lv = node.child_nodes[1].makeCodeParts(test, dost)
  #     if li[1] == lv[1]:
  #       if identExistenceCheck(li[0][1][1]):
  #         echoErrorMessage("既に定義されています", test, node.token.Line)
  #       code.add(li[0])
  #       code.add((OTHER, "="))
  #       code.add(lv[0])
  #       code.addSemicolon()
  #       identTable[li[0][1][1]] = IdentInfo(
  #         Type:     li[1],
  #         contents: lv[0],
  #         path:     nesting,
  #         mutable:  false,
  #         used:     false,
  #       )
  #       addScopeTable(li[0][1][1], nesting)
  #     else:
  #       echoErrorMessage("指定している型と値の型が違います", test, node.token.Line)
  #   else:
  #     echoErrorMessage("不明なエラー", test, node.token.Line)
  
  # var文
  # of nkVarStatement:
    # if node.child_nodes.len() == 1:
    #   let li = node.child_nodes[0].makeCodeParts(test, dost)
    #   if identExistenceCheck(li[0][1][1]):
    #     echoErrorMessage("既に定義されています", test, node.token.Line)
    #   else:
    #     code.add(li[0])
    #     code.addSemicolon()
    #     identTable[li[0][1][1]] = IdentInfo(
    #       Type:     li[1],
    #       contents: @[],
    #       path:     nesting,
    #       mutable:  true,
    #       used:   false,
    #     )
    #     addScopeTable(li[0][1][1], nesting)
    # if node.child_nodes.len() == 2:
    #   let li = node.child_nodes[0].makeCodeParts(test, dost)
    #   let lv = node.child_nodes[1].makeCodeParts(test, dost)
    #   if li[1] == lv[1]:
    #     if identExistenceCheck(li[0][1][1]):
    #       echoErrorMessage("既に定義されています", test, node.token.Line)
    #     code.add(li[0])
    #     code.add((OTHER, "="))
    #     code.add(lv[0])
    #     code.addSemicolon()
    #     identTable[li[0][1][1]] = IdentInfo(
    #       Type:     li[1],
    #       contents: lv[0],
    #       path:     nesting,
    #       mutable:  true,
    #       used:     false,
    #     )
    #     addScopeTable(li[0][1][1], nesting)
    #   else:
    #     echoErrorMessage("指定している型と値の型が違います", test, node.token.Line)
    # else:
    #   echoErrorMessage("不明なエラー", test, node.token.Line)

  of nkMainStatement:
    var new_dost = true
    let di = node.child_nodes[0].makeCodeParts(test, new_dost)
    if identExistenceCheck(di[0][1][1]):
      echoErrorMessage("既に定義されています", test, node.token.Line)
    # echo di
    code.add((OTHER, di[0][0].Code))
    code.add(di[0][1])
    if node.child_nodes[1].child_nodes == @[]:
      identTable[di[0][1][1]] = IdentInfo(
        Type:    NIL & "+" & di[1],
        path:    nesting,
        mutable: false,
        used:  false,
      )
      addScopeTable(di[0][1][1], nesting)
    else:
      var argsType: seq[string]
      for parameter in node.child_nodes[1].child_nodes:
        argsType.add(parameter.token.Type.removeT())
      identTable[di[0][1][1]] = IdentInfo(
        Type:    argsType.join("+") & "+" & di[1],
        path:    nesting,
        mutable: false,
        used:  false,
      )
      addScopeTable(di[0][1][1], nesting)
    var origin = nesting
    nesting = nesting + 1
    if node.child_nodes[1].child_nodes == @[]:
      code.add((OTHER, "()"))
      code.add((OTHER, "{"))
      for statement in node.child_nodes[2].child_nodes:
        if statement.kind == nkReturnStatement:
          let st = statement.makeCodeParts(test, new_dost)
          if typeMatch(st[1], di[1])[0]:
            code.add(st[0])
          else:
            echoErrorMessage("指定している型と返り値の型が違います", test, node.token.Line)
        else:
          code.add(statement.makeCodeParts(test, new_dost)[0])
    else:
      code.add((OTHER, "("))
      for i, parameter in node.child_nodes[1].child_nodes:
        if i != 0:
          code.add((OTHER, ","))
        let pr = parameter.makeCodeParts(test, new_dost)
        code.add(pr[0])
        identTable[parameter.child_nodes[0].token.Literal] = IdentInfo(
          Type:    pr[1],
          path:    nesting,
          mutable: false,
          used:  false,
        )
        addScopeTable(parameter.child_nodes[0].token.Literal, nesting)
      code.add((OTHER, ")"))
      code.add((OTHER, "{"))
      for statement in node.child_nodes[2].child_nodes:
        if statement.kind == nkReturnStatement:
          let st = statement.makeCodeParts(test, new_dost)
          if typeMatch(st[1], di[1])[0]:
            code.add(st[0])
          else:
            echoErrorMessage("指定している型と返り値の型が違います", test, node.token.Line)
        else:
          code.add(statement.makeCodeParts(test, new_dost)[0])
    # nestingをリセット
    nesting = origin
    code.add(deleteScope(nesting, test))
    code.add((OTHER, "}"))
    codeType = MAIN

  # def文
  of nkDefineStatement:
    var new_dost = true
    let di = node.child_nodes[0].makeCodeParts(test, new_dost)
    if identExistenceCheck(di[0][1][1]):
      echoErrorMessage("既に定義されています", test, node.token.Line)
    # echo di
    code.add(di[0][0])
    code.add(di[0][1])
    if node.child_nodes[1].child_nodes == @[]:
      identTable[di[0][1][1]] = IdentInfo(
        Type:    NIL & "->" & di[1],
        path:    nesting,
        mutable: false,
        used:  false,
      )
      addScopeTable(di[0][1][1], nesting)
    else:
      var argsType: seq[string]
      for parameter in node.child_nodes[1].child_nodes:
        argsType.add(parameter.token.Type.removeT())
      identTable[di[0][1][1]] = IdentInfo(
        Type:    argsType.join("+") & "->" & di[1],
        path:    nesting,
        mutable: false,
        used:  false,
      )
      addScopeTable(di[0][1][1], nesting)
    var origin = nesting
    nesting = nesting + 1
    if node.child_nodes[1].child_nodes == @[]:
      code.add((OTHER, "()"))
      code.add((OTHER, "{"))
      for statement in node.child_nodes[2].child_nodes:
        if statement.kind == nkReturnStatement:
          let st = statement.makeCodeParts(test, new_dost)
          if typeMatch(st[1], di[1])[0]:
            code.add(st[0])
          else:
            echoErrorMessage("指定している型と返り値の型が違います", test, node.token.Line)
        else:
          code.add(statement.makeCodeParts(test, dost)[0])
    else:
      code.add((OTHER, "("))
      for i, parameter in node.child_nodes[1].child_nodes:
        if i != 0:
          code.add((OTHER, ","))
        let pr = parameter.makeCodeParts(test, new_dost)
        code.add(pr[0])
        identTable[parameter.child_nodes[0].token.Literal] = IdentInfo(
          Type:    pr[1],
          path:    nesting,
          mutable: false,
          used:  false,
        )
        addScopeTable(parameter.child_nodes[0].token.Literal, nesting)
      code.add((OTHER, ")"))
      code.add((OTHER, "{"))
      for statement in node.child_nodes[2].child_nodes:
        if statement.kind == nkReturnStatement:
          let st = statement.makeCodeParts(test, new_dost)
          if typeMatch(st[1], di[1])[0]:
            code.add(st[0])
          else:
            echoErrorMessage("指定している型と返り値の型が違います", test, node.token.Line)
        else:
          code.add(statement.makeCodeParts(test, new_dost)[0])
    # nestingをリセット
    nesting = origin
    code.add(deleteScope(nesting, test))
    code.add((OTHER, "}"))
    codeType = DEFINE

  # return文
  of nkReturnStatement:
    if node.child_nodes != @[]:
      var new_dost = true
      code.add((OTHER, "return"))
      code.add((OTHER, "("))
      let r = node.child_nodes[0].makeCodeParts(test, new_dost)
      code.add(r[0].replaceSemicolon(@[(OTHER, "")]))
      code.add((OTHER, ")"))
      code.addSemicolon()
      codeType = r[1]
    else:
      echoErrorMessage("式がありません", test, node.token.Line)
  
  # 中置
  of nkInfixExpression:
    if dost == false:
      echoErrorMessage("文の外で関数を呼び出すことはできません", test, node.token.Line)

    var 
      l: (seq[codeParts], string)
      r: (seq[codeParts], string)
    if node.child_nodes.len() != 2:
      echoErrorMessage("オペランドがありません", test, node.token.Line)
    l = node.child_nodes[0].makeCodeParts(test, dost)
    r = node.child_nodes[1].makeCodeParts(test, dost)
    if l[1] == r[1]:
      let oc = node.token.Literal.conversionCppOperator(@[l[1], r[1]])
      if oc[0] == false:
        echoErrorMessage("オペランドの型が間違っています", test, node.token.Line)
      code.add(((OTHER, "(")))
      code.add(l[0].replaceSemicolon(@[(OTHER, "")]))
      code.add((node.token.Type, oc[2]))
      code.add(r[0].replaceSemicolon(@[(OTHER, "")]))
      code.add(((OTHER, ")")))
      code.addSemicolon()
      codeType = oc[1]
    else:
      echoErrorMessage("オペランドの型がそれぞれ違います", test, node.token.Line)
  
  # Generator
  of nkGenerator:
    # TODO: 型のチェック
    var lt: string
    if node.child_nodes.len() == 2:
      let l = node.child_nodes[0].makeCodeParts(test, dost)
      code.add(l[0])
      lt = l[1]
      nesting = nesting + 1
      if identExistenceCheck(l[0][1][1]):
        echoErrorMessage("既に定義されています", test, node.token.Line)
      identTable[l[0][1][1]] = IdentInfo(
        Type:    lt,
        path:    nesting,
        mutable: false,
        used:  false,
      )
      codeType = l[1]
      
      code.add((COLON, ":"))

      let r = node.child_nodes[1].makeCodeParts(test, dost)
      if lt == r[1].funcTypeSplit("ARRAY::")[2]:
        code.add(r[0])
      else:
        echoErrorMessage("指定している型と値の型が違います", test, node.token.Line)
    else:
      echoErrorMessage("式がありません", test, node.token.Line)

  # パイプライン演算子
  of nkPipeExpression:
    echoErrorMessage("対象が関数ではありません", test, node.token.Line)

  # 配列の要素へのアクセス
  of nkAccessElement:
    if node.child_nodes.len() == 2:
      let l = node.child_nodes[0].makeCodeParts(test, dost)
      let r = node.child_nodes[1].makeCodeParts(test, dost)
      let rv = r[0].replaceSemicolon(@[(OTHER, "")])
      let ls = l[1].split("::")
      if r[1] == INT and ls[0] == ARRAY:
        code.add(l[0].replaceSemicolon(@[(OTHER, "")]))
        code.add((OTHER, "["))
        code.add(rv)
        code.add((OTHER, "]"))
        code.addSemicolon()
        codeType = ls[1..ls.len()-1].join("::")
      else:
        echoErrorMessage("オペランドの型が間違っています", test, node.token.Line)
    else:
      echoErrorMessage("オペランドがありません", test, node.token.Line)

  # 代入式
  of nkAssignExpression:
    var lt, rt: string
    var lmc: string
    if node.child_nodes.len() == 2:
      # 値を代入しようとしている変数のチェック
      let l = node.child_nodes[0].makeCodeParts(test, dost)
      lmc = l[0][l[0].len()-1].Code
      if lmc == ";":
        lmc = l[0][l[0].len()-2].Code
      if identExistenceCheck(lmc):
        if identTable[lmc].mutable == false:
          echoErrorMessage("代入しようとしている変数がイミュータブルです", test, node.token.Line)
      else:
        echoErrorMessage("定義されていない名前です", test, node.token.Line)
      code.add(l[0].replaceSemicolon(@[(OTHER, "")]))
      lt = l[1]

      code.add((OTHER, "="))
      let r = node.child_nodes[1].makeCodeParts(test, dost)
      code.add(r[0])
      identTable[lmc].contents = r[0]
      rt = r[1]
    else:
      echoErrorMessage("オペランドがありません", test, node.token.Line)
    code.addSemicolon()
    if typeMatch(lt, rt)[0]:
      codeType = lt
    else:
      echoErrorMessage("オペランドの型がそれぞれ違います", test, node.token.Line)

  # 前置
  # TODO 
  of nkCallExpression:
    if dost == false:
      echoErrorMessage("文の外で関数を呼び出すことはできません", test, node.token.Line)

    var
      argsCode: seq[seq[codeParts]]
      argsType: seq[string]

    for i, arg in node.child_nodes[1].child_nodes:
      let a = arg.makeCodeParts(test, dost)
      argsCode.add(a[0].replaceSemicolon(@[(OTHER, "")]))
      argsType.add(a[1])
    let funcName = node.child_nodes[0].token.Literal
    let iec = identExistenceCheck(funcName)
    if iec:
      let ftm = funcTypesMatch(identTable[funcName].Type, argsType)
      if ftm[0]:
        code.add((IDENT, funcName))
        codeType = ftm[2]
      else:
        echoErrorMessage("引数の型が正しくありません", test, node.token.Line)
    else:
      let ccf = conversionCppFunction(funcName, argsType)
      if ccf[0]:
        code.add((IDENT, ccf[2]))
        codeType = ccf[1]
      else:
        if ccf[1] == OTHER:
          echoErrorMessage("引数の型が正しくありません", test, node.token.Line)
        else:
          echoErrorMessage("定義されていない名前です", test, node.token.Line)
    
    code.add((OTHER, "("))
    for i, argc in argsCode:
      if i != 0:
        code.add((OTHER, ","))
      code.add(argc)
    code.add((OTHER, ")"))
    code.addSemicolon()

  # map関数
  of nkMapFunction:
    if dost == false:
      echoErrorMessage("文の外で関数を呼び出すことはできません", test, node.token.Line)

    if node.child_nodes[0].child_nodes.len() != 2:
      echoErrorMessage("引数の数が合いません", test, node.token.Line)
    elif node.child_nodes[0].child_nodes[1].kind != nkCallExpression:
      echoErrorMessage("第二引数が正しくありません", test, node.token.Line)

    let func_name = node.child_nodes[0].child_nodes[1].child_nodes[0].token.Literal
    var cpp_func_name = ""
    var func_result_type = ""
    let array_CandT = node.child_nodes[0].child_nodes[0].makeCodeParts(test, dost)
    let array_content = array_CandT[0]
    let array_type = array_CandT[1]
    let array_type_split = array_type.split("::")
    var fn = node.child_nodes[0].child_nodes[1]
    
    var func_arg_types: seq[string]
    for nodes in fn.child_nodes[1].child_nodes:
      func_arg_types.add(nodes.token.Type)

    if array_type_split[0] != ARRAY:
      echoErrorMessage("第一引数の型が正しくありません", test, node.token.Line)

    let i_node = Node(
      kind:        nkIdent,
      token:       Token(Type: IDENT, Literal: "i"),
      child_nodes: @[],
    )
    fn.child_nodes[1].child_nodes = @[i_node] & fn.child_nodes[1].child_nodes

    let ccf = conversionCppFunction(func_name, array_type_split[1..array_type_split.len()-1] & func_arg_types)
    if ccf[0]:
      cpp_func_name = ccf[2]
      func_result_type = ccf[1]
    else:
      if identExistenceCheck(func_name) == false:
        if ccf[1] == NIL:
          echoErrorMessage("存在しない関数です", test, node.token.Line)
        else:
          echoErrorMessage("第二引数の関数の引数が正しくありません", test, node.token.Line)
      else:
        let ftm = funcTypesMatch(identTable[func_name].Type, array_type_split[1..array_type_split.len()-1] & func_arg_types)
        if ftm[0]:
          cpp_func_name = func_name
          func_result_type = ftm[2]
        else:  
          echoErrorMessage("第二引数の関数の引数が正しくありません", test, node.token.Line)

    if func_result_type.split("::") != array_type_split[1..array_type_split.len()-1]:
      echoErrorMessage("第二引数の関数の返り値が正しくありません", test, node.token.Line)

    code.add((IDENT, "ka23::map"))
    code.add((OTHER, "("))
    code.add(array_content)
    code.add((OTHER, ","))
    code.add((OTHER, "[]"))
    code.add((OTHER, "("))
    let ident = Node(
      kind:        nkVarStatement,
      token:       Token(Type: VAR, Literal: "var"),
      child_nodes: @[Node(
        kind:        nkArrayType,
        token:       Token(Type: "T_" & array_type_split[1..array_type_split.len()-1].join("::T_"), Literal:"{"),
        child_nodes: @[Node(
          kind:        nkIdent,
          token:       Token(Type: IDENT, Literal: "i"),
          child_nodes: @[],
        )],
      )],
    )
    code.add(ident.makeCodeParts(test, dost)[0].replaceSemicolon(@[(OTHER, "")]))
    code.add((OTHER, ")"))
    code.add((LBRACE, "{"))
    code.add((OTHER, "return"))
    code.add((OTHER, cpp_func_name))
    code.add((OTHER, "("))
    for i, arg in fn.child_nodes[1].child_nodes:
      if i != 0:
        code.add((OTHER, ","))
      code.add(arg.makeCodeParts(test, dost)[0].replaceSemicolon(@[(OTHER, "")]))
    code.add((OTHER, ")"))
    code.add((OTHER, ";"))
    code.add((RBRACE, "}"))
    code.add((OTHER, ")"))
    code.addSemicolon()

  # if文
  of nkIfStatement:
    var new_dost = true
    code.add((OTHER, "if"))
    code.add((OTHER, "("))
    code.add(node.child_nodes[0].makeCodeParts(test, new_dost)[0].replaceSemicolon(@[(OTHER, "")]))
    code.add((OTHER, ")"))
    code.add((OTHER, "{"))
    var sr: (seq[codeParts], string)
    for i, statement in node.child_nodes[1].child_nodes:
      if i == node.child_nodes[1].child_nodes.len()-1:
        sr = statement.makeCodeParts(test, new_dost)
        code.add(sr[0])
      else:
        sr = statement.makeCodeParts(test, new_dost)
        code.add(sr[0])
    code.add((OTHER, "}"))
    if node.child_nodes.len() == 3:
      let ar = node.child_nodes[2].makeCodeParts(test, new_dost)
      code.add(ar[0])
    else:
      code.add((OTHER, "\n"))
    codeType = sr[1]

  # elif文
  of nkElifStatement:
    var new_dost = true
    code.add((OTHER, "else if"))
    code.add((OTHER, "("))
    code.add(node.child_nodes[0].makeCodeParts(test, new_dost)[0].replaceSemicolon(@[(OTHER, "")]))
    code.add((OTHER, ")"))
    code.add((OTHER, "{"))
    var sr: (seq[codeParts], string)
    for i, statement in node.child_nodes[1].child_nodes:
      if i == node.child_nodes[1].child_nodes.len()-1:
        sr = statement.makeCodeParts(test, new_dost)
        code.add(sr[0])
      else:
        sr = statement.makeCodeParts(test, new_dost)
        code.add(sr[0])
    code.add((OTHER, "}"))
    if node.child_nodes.len() == 3:
      let ar = node.child_nodes[2].makeCodeParts(test, new_dost)
      code.add(ar[0])
    else:
      code.add((OTHER, "\n"))
    codeType = sr[1]

  # else文
  of nkElseStatement:
    var new_dost = true
    code.add((OTHER, "else"))
    code.add((OTHER, "{"))
    var sr: (seq[codeParts], string)
    for i, statement in node.child_nodes[0].child_nodes:
      if i == node.child_nodes[0].child_nodes.len()-1:
        sr = statement.makeCodeParts(test, new_dost)
        code.add(sr[0])
      else:
        sr = statement.makeCodeParts(test, new_dost)
        code.add(sr[0])
    code.add((OTHER, "}"))
    codeType = sr[1]
  
  # if式
  of nkIfExpression:
    code.add((OTHER, "("))
    code.add(node.child_nodes[0].makeCodeParts(test, dost)[0].replaceSemicolon(@[(OTHER, "")]))
    code.add((OTHER, "?"))
    var sr = node.child_nodes[1].makeCodeParts(test, dost)
    code.add(sr[0].replaceSemicolon(@[(OTHER, "")]))
    let ar = node.child_nodes[2].makeCodeParts(test, dost)
    if typeMatch(ar[1], sr[1])[0]:
      code.add((OTHER, ":"))
      code.add(ar[0].replaceSemicolon(@[(OTHER, "")]))
      codeType = sr[1]
      code.add((OTHER, ")"))
      code.addSemicolon()
    else:
      echoErrorMessage("返り値の型が異なっています", test, node.token.Line)

  # else式
  of nkElseExpression:
    var sr = node.child_nodes[0].makeCodeParts(test, dost)
    code.add(sr[0].replaceSemicolon(@[(OTHER, "")]))
    codeType = sr[1]

  # for文
  # TODO
  of nkForStatement:
    var new_dost = true
    let origin = nesting
    code.add((OTHER, "for"))
    code.add((OTHER, "("))
    code.add(node.child_nodes[0].makeCodeParts(test, new_dost)[0])
    code.add((OTHER, ")"))
    code.add((OTHER, "{"))
    var sr: (seq[codeParts], string)
    for i, statement in node.child_nodes[1].child_nodes:
      sr = statement.makeCodeParts(test, new_dost)
      code.add(sr[0])
    nesting = origin
    code.add(deleteScope(nesting, test))
    code.add((OTHER, "}"))
    codeType = sr[1]
  else:
    return (code, codeType)
  
  return (code, codeType)

proc makeCppCode*(node: Node, indent: int, test: bool): string =
  var parts: (seq[codeParts], string)
  var dost = false
  for child in node.child_nodes:
    parts[0].add(makeCodeParts(child, test, dost)[0])
  var outCode: seq[string]
  var newLine: string
  var braceCount: int = indent
  
  for d in deleteScope(-1, test):
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
      outCode.add(ind & newLine & "\n")
      braceCount = braceCount + 1
      newLine = ""
    elif part.Type == OTHER and (part.Code == "}" or part.Code == "} ;"):
      if newLine.split(" ").join("") != "":
        outCode.add(newLine)
      braceCount = braceCount - 1
      newLine = ""
      newLine.addIndent(braceCount)
      newLine.add(part.Code)
      outCode.add(newLine & "\n")
      newLine = ""
    elif part.Type == OTHER and part.Code == "\n":
      newLine.add(part.Code)
    else:
      newLine.add(part.Code & " ")
    
  outCode.add(newLine)
  
  return outCode.join()