import g_token, g_node, g_token, g_error, g_show
import strutils, tables, os

#------↓仮↓------

type codeParts = tuple
  Type: string
  Code: string

type IdentInfo* = ref object of RootObj
  Type*:        string
  member*:      seq[(string, IdentInfo)]
  init*:        bool
  path:         int
  mutable*:     bool
  used*:        bool

type TypeInfo* = ref object of RootObj
  Type*:        string
  member*:      seq[(string, TypeInfo)]
  code*:        string
  path:         int
  mutable*:     bool
  used*:        bool

var
  #                      ↓名前    ↓情報
  identTable = initTable[string, IdentInfo]()
  typeTable  = initTable[string, TypeInfo]()
  #                      ↓ネストの深さ  ↓そのスコープに含まれる変数名と型名の配列
  scopeTable = initTable[int,         seq[string]]()
  nesting = 0

proc initTables*() =
  identTable = initTable[string, IdentInfo]()
  scopeTable = initTable[int, seq[string]]()
  nesting = 0

proc deleteScope(n: int, test: bool): seq[codeParts]

proc nestingIncrement() =
  nesting = nesting + 1

proc nestingReset(original: int, test: bool) =
  nesting = original
  discard deleteScope(nesting, test)

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

proc identRegistration(info: IdentInfo, ident_name: string, n: int) =
  identTable[ident_name] = info

  if scopeTable.contains(n):
    var flag = false
    for element in scopeTable[n]:
      if element == ident_name:
        flag = true
    # まだ登録されていなければ追加する
    if flag == false:
      scopeTable[n].add(ident_name)
  else:
    scopeTable[n] = @[ident_name]
  
proc typeRegistration(info: TypeInfo, type_name: string, n: int) =
  typeTable[type_name] = info

  if scopeTable.contains(n):
    var flag = false
    for element in scopeTable[n]:
      if element == type_name:
        flag = true
    # まだ登録されていなければ追加する
    if flag == false:
      scopeTable[n].add(type_name)
  else:
    scopeTable[n] = @[type_name]

proc deleteScope(n: int, test: bool): seq[codeParts] =
  if scopeTable.len()-1 > n:
    var new_scopeTable = initTable[int, seq[string]]()
    for i in 0..n:
      new_scopeTable[i] = scopeTable[i]

    for i in n+1..scopeTable.len()-1:
      for ident in scopeTable[i]:
        identTable.del(ident)

    scopeTable = new_scopeTable

proc memberSearch(member: seq[(string, IdentInfo)], target: string): (bool, IdentInfo) =
  var target_split = target.split(".")
  
  if target_split.len() == 1:
    for elem in member:
      if elem[0] == target_split[0]:
        return (true, elem[1])
  else:
    for elem in member:
      if elem[0] == target_split[0]:
        return memberSearch(elem[1].member, target_split[1..target_split.len()-1].join("."))
  
  return (false, IdentInfo())

proc identExistenceCheck(ident: string): (bool, IdentInfo) =
  var ident_split = ident.split(".")

  if ident_split.len() == 1:
    if identTable.contains(ident_split[0]):
      if identTable[ident_split[0]].path <= nesting and identTable[ident_split[0]].init == true:
        return (true, identTable[ident_split[0]])
  else:
    if identTable.contains(ident_split[0]):
      if identTable[ident_split[0]].path <= nesting and identTable[ident_split[0]].init == true:
        return (false, memberSearch(identTable[ident_split[0]].member, ident_split[1..ident_split.len()-1].join("."))[1])
  
  return (false, IdentInfo())

proc typeExistenceCheck(Type: string): bool =
  if typeTable.contains(Type):
    if typeTable[Type].path <= nesting:
      return true
  
  return false

# 返り値1: マッチ結果, 返り値2: 型変数の値の配列
proc typePartMatch(type1: string, type2: string): (bool, seq[(string, string)]) =
  var
    flow: seq[string]
    match = false
    vars: seq[(string, string)]
    t1_bar_s = type1.split("|")
    t1_bar_s_cc_s: seq[string]
    t2_cc_s = type2.split("::")

  for part in t1_bar_s:
    t1_bar_s_cc_s = part.split("::")
    for i, elem in t1_bar_s_cc_s:
      match = false
      if elem.startsWith("@"):
        vars.add((elem, t2_cc_s[i..t2_cc_s.len()-1].join("::")))
        flow.add(t2_cc_s[i..t2_cc_s.len()-1].join("::"))
        match = true
        break
      elif elem == t2_cc_s[i]:
        flow.add(elem)
        match = true
      else:
        break
    if match:
      return (true, vars)
  
  return (false, vars)

# 返り値1: マッチ結果, 返り値2: 返り値の型, 返り値3: 型変数の値の配列
proc funcTypesMatch(fn_type: string, arg_type: string): (bool, string, seq[(string, string)]) =
  # 引数部と返り値部を分ける
  var
    fn_type_a = fn_type.split("->")[0]
    fn_type_r = fn_type.split("->")[1]
    fn_type_a_s = fn_type_a.split("+")
    arg_type_s  = arg_type.split("+")
    vars: seq[(string, string)]
  
  for i, ftas_part in fn_type_a_s:
    var match_res = typePartMatch(ftas_part, arg_type_s[i])
    if match_res[0]:
      vars.add(match_res[1])
    else:
      return (false, "", @[])

  if fn_type_r.startsWith("@"):
    for (name, Type) in vars:
      if name == fn_type_r:
        return (true, Type, vars)
    return (false, "", @[])
  else:
    return (true, fn_type_r, vars)

proc typeFilter(types: seq[(string, string)], target: string, filter: string): (bool, string) =
  var fl = filter.split("|")
  var results: seq[string]

  for i, t in types:
    for f in fl:
      if t[0] == target and t[1] == f and results.contains(t[1]) == false:
        results.add(t[1])
  
  if results == @[]:
    return (false, "")
  else:
    return (true, results.join("|"))

proc conversionCppType(Type: string, test: bool, line: int): (string, string) =
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
      return (T_ARRAY & "::" & ts[1..ts.len()-1].join("::").conversionCppType(test, line)[0], "std::vector<" & ts[1..ts.len()-1].join("::").conversionCppType(test, line)[1] & ">")
    of T_FUNCTION:
      return (T_FUNCTION, "auto")
    else:
      if typeExistenceCheck(Type):
        return ("T_" & Type, typeTable[Type].code)
      else:
        echoErrorMessage("\"" & Type & "\"が存在しません", test, line)

# 型のチェックをしてC++の演算子に変換する 
proc conversionCppOperator(fn: string, argsType: seq[string]): (bool, string, string) =
  let anything_t = INT & "|" & FLOAT & "|" & CHAR & "|" & STRING & "|" & BOOL
  let number_t = INT & "|" & FLOAT

  case fn
  of PLUS:
    var ftm_res = funcTypesMatch("@a" & "+" & "@a" & "->" & "@a", argsType.join("+"))
    if ftm_res[0] == false:
      return (false, OTHER, "+")
    var tf_res = ftm_res[2].typeFilter("@a", number_t)
    if tf_res[0] == false:
      return (false, OTHER, "+")
    
    return (true, tf_res[1], "+")
  of MINUS:
    var ftm_res = funcTypesMatch("@a" & "+" & "@a" & "->" & "@a", argsType.join("+"))
    if ftm_res[0] == false:
      return (false, OTHER, "-")
    var tf_res = ftm_res[2].typeFilter("@a", number_t)
    if tf_res[0] == false:
      return (false, OTHER, "-")
    
    return (true, tf_res[1], "-")
  of ASTERISC:
    var ftm_res = funcTypesMatch("@a" & "+" & "@a" & "->" & "@a", argsType.join("+"))
    if ftm_res[0] == false:
      return (false, OTHER, "*")
    var tf_res = ftm_res[2].typeFilter("@a", number_t)
    if tf_res[0] == false:
      return (false, OTHER, "*")
    
    return (true, tf_res[1], "*")
  of SLASH:
    var ftm_res = funcTypesMatch("@a" & "+" & "@a" & "->" & "@a", argsType.join("+"))
    if ftm_res[0] == false:
      return (false, OTHER, "/")
    var tf_res = ftm_res[2].typeFilter("@a", number_t)
    if tf_res[0] == false:
      return (false, OTHER, "/")
    
    return (true, tf_res[1], "/")
  of LT:
    var ftm_res = funcTypesMatch("@a" & "+" & "@a" & "->" & BOOL, argsType.join("+"))
    if ftm_res[0] == false:
      return (false, OTHER, "<")
    var tf_res = ftm_res[2].typeFilter("@a", number_t)
    if tf_res[0] == false:
      return (false, OTHER, "<")
    
    return (true, BOOL, "<")
  of GT:
    var ftm_res = funcTypesMatch("@a" & "+" & "@a" & "->" & BOOL, argsType.join("+"))
    if ftm_res[0] == false:
      return (false, OTHER, ">")
    var tf_res = ftm_res[2].typeFilter("@a", number_t)
    if tf_res[0] == false:
      return (false, OTHER, ">")
    
    return (true, BOOL, ">")
  of LE:
    var ftm_res = funcTypesMatch("@a" & "+" & "@a" & "->" & BOOL, argsType.join("+"))
    if ftm_res[0] == false:
      return (false, OTHER, "<=")
    var tf_res = ftm_res[2].typeFilter("@a", number_t)
    if tf_res[0] == false:
      return (false, OTHER, "<=")
    
    return (true, BOOL, "<=")
  of GE:
    var ftm_res = funcTypesMatch("@a" & "+" & "@a" & "->" & BOOL, argsType.join("+"))
    if ftm_res[0] == false:
      return (false, OTHER, ">=")
    var tf_res = ftm_res[2].typeFilter("@a", number_t)
    if tf_res[0] == false:
      return (false, OTHER, ">=")
    
    return (true, BOOL, ">=")
  of EE:
    var ftm_res = funcTypesMatch("@a" & "+" & "@a" & "->" & BOOL, argsType.join("+"))
    if ftm_res[0] == false:
      return (false, OTHER, "==")
    var tf_res = ftm_res[2].typeFilter("@a", anything_t)
    if tf_res[0] == false:
      return (false, OTHER, "==")

    return (true, BOOL, "==")
  of NE:
    var ftm_res = funcTypesMatch("@a" & "+" & "@a" & "->" & BOOL, argsType.join("+"))
    if ftm_res[0] == false:
      return (false, OTHER, "!=")
    var tf_res = ftm_res[2].typeFilter("@a", anything_t)
    if tf_res[0] == false:
      return (false, OTHER, "!=")
    
    return (true, BOOL, "!=")
  of AMPERSAND:
    var ftm_res = funcTypesMatch("@a" & "+" & "@a" & "->" & "@a", argsType.join("+"))
    if ftm_res[0] == false:
      return (false, OTHER, "&")
    var tf_res = ftm_res[2].typeFilter("@a", STRING)
    if tf_res[0] == false:
      return (false, OTHER, "&")
  
    return (true, BOOL, "&")

# 型のチェックをしてC++の関数に変換する
proc conversionCppFunction(fn: string, argsType: seq[string]): (bool, string, string) =
  let anything_t = INT & "|" & FLOAT & "|" & CHAR & "|" & STRING & "|" & BOOL
  let number_t = INT & "|" & FLOAT
  let letter_t = CHAR & "|" & STRING
  var argsTypeC = argsType

  case fn
  of "plus":
    if argsTypeC.len() == 0:
      return (true, IDENT, "grid::plus")
    elif argsTypeC.len() == 2:
      var ftm_res = funcTypesMatch("@a" & "+" & "@a" & "->" & "@a", argsType.join("+"))
      if ftm_res[0] == false:
        return (false, OTHER, "grid::plus")
      var tf_res = ftm_res[2].typeFilter("@a", number_t)
      if tf_res[0] == false:
        return (false, OTHER, "grid::plus")
      
      return (true, tf_res[1], "grid::plus")
    else:
      return (false, OTHER, "")
  of "minu":
    if argsTypeC.len() == 0:
      return (true, IDENT, "grid::minu")
    elif argsTypeC.len() == 2:
      var ftm_res = funcTypesMatch("@a" & "+" & "@a" & "->" & "@a", argsType.join("+"))
      if ftm_res[0] == false:
        return (false, OTHER, "grid::minu")
      var tf_res = ftm_res[2].typeFilter("@a", number_t)
      if tf_res[0] == false:
        return (false, OTHER, "grid::minu")
      
      return (true, tf_res[1], "grid::minu")
    else:
      return (false, OTHER, "")
  of "mult":
    if argsTypeC.len() == 0:
      return (true, IDENT, "grid::mult")
    elif argsTypeC.len() == 2:
      var ftm_res = funcTypesMatch("@a" & "+" & "@a" & "->" & "@a", argsType.join("+"))
      if ftm_res[0] == false:
        return (false, OTHER, "grid::mult")
      var tf_res = ftm_res[2].typeFilter("@a", number_t)
      if tf_res[0] == false:
        return (false, OTHER, "grid::mult")
      
      return (true, tf_res[1], "grid::mult")
    else:
      return (false, OTHER, "")
  of "divi":
    if argsTypeC.len() == 0:
      return (true, IDENT, "grid::divi")
    elif argsTypeC.len() == 2:
      var ftm_res = funcTypesMatch("@a" & "+" & "@a" & "->" & "@a", argsType.join("+"))
      if ftm_res[0] == false:
        return (false, OTHER, "grid::divi")
      var tf_res = ftm_res[2].typeFilter("@a", number_t)
      if tf_res[0] == false:
        return (false, OTHER, "grid::divi")
      
      return (true, tf_res[1], "grid::divi")
    else:
      return (false, OTHER, "")
  of "print":
    if argsTypeC.len() == 0:
      return (true, IDENT, "grid::print")
    elif argsTypeC.len() == 1:
      var ftm_res = funcTypesMatch(letter_t & "->" & NIL, argsType.join("+"))
      if ftm_res[0] == false:
        return (false, OTHER, "grid::print")
      
      return (true, NIL, "grid::print")
    else:
      return (false, OTHER, "")
  of "println":
    if argsTypeC.len() == 0:
      return (true, IDENT, "grid::println")
    elif argsTypeC.len() == 1:
      var ftm_res = funcTypesMatch(letter_t & "->" & NIL, argsType.join("+"))
      if ftm_res[0] == false:
        return (false, OTHER, "grid::println")
      
      return (true, NIL, "grid::println")
    else:
      return (false, OTHER, "")
  of "len":
    if argsTypeC.len() == 0:
      return (true, IDENT, "grid::len")
    elif argsTypeC.len() == 1:
      var ftm_res = funcTypesMatch("ARRAY::@a" & "->" & "INT", argsType.join("+"))
      if ftm_res[0] == false:
        return (false, OTHER, "grid::len")
      
      return (true, INT, "grid::len")
    else:
      return (false, OTHER, "")
  of "join":
    if argsTypeC.len() == 0:
      return (true, IDENT, "grid::join")
    elif argsTypeC.len() == 2:
      var ftm_res = funcTypesMatch("ARRAY::@a" & "+" & "ARRAY::@a" & "->" & "ARRAY::@a", argsType.join("+"))
      if ftm_res[0] == false:
        return (false, OTHER, "grid::join")
      
      return (true, ftm_res[1], "grid::join")
    else:
      return (false, OTHER, "")
  of "head":
    if argsTypeC.len() == 0:
      return (true, IDENT, "grid::join")
    elif argsTypeC.len() == 1:
      var ftm_res = funcTypesMatch("ARRAY::@a" & "->" & "@a", argsType.join("+"))
      if ftm_res[0] == false:
        return (false, OTHER, "grid::head")
      
      return (true, ftm_res[1], "grid::head")
    else:
      return (false, OTHER, "")
  of "tail":
    if argsTypeC.len() == 0:
      return (true, IDENT, "grid::tail")
    elif argsTypeC.len() == 1:
      var ftm_res = funcTypesMatch("ARRAY::@a" & "->" & "ARRAY::@a", argsType.join("+"))
      if ftm_res[0] == false:
        return (false, OTHER, "grid::tail")
      
      return (true, ftm_res[1], "grid::tail")
    else:
      return (false, OTHER, "")
  of "last":
    if argsTypeC.len() == 0:
      return (true, IDENT, "grid::last")
    elif argsTypeC.len() == 1:
      var ftm_res = funcTypesMatch("ARRAY::@a" & "->" & "@a", argsType.join("+"))
      if ftm_res[0] == false:
        return (false, OTHER, "grid::last")
      
      return (true, ftm_res[1], "grid::last")
    else:
      return (false, OTHER, "")
  of "init":
    if argsTypeC.len() == 0:
      return (true, IDENT, "grid::init")
    elif argsTypeC.len() == 1:
      var ftm_res = funcTypesMatch("ARRAY::@a" & "->" & "ARRAY::@a", argsType.join("+"))
      if ftm_res[0] == false:
        return (false, OTHER, "grid::init")
      
      return (true, ftm_res[1], "grid::init")
    else:
      return (false, OTHER, "")
  of "toString":
    if argsTypeC.len() == 0:
      return (true, IDENT, "grid::toString")
    elif argsTypeC.len() == 1:
      var ftm_res = funcTypesMatch(anything_t & "->" & STRING, argsType.join("+"))
      if ftm_res[0] == false:
        return (false, OTHER, "grid::toString")
      
      return (true, STRING, "grid::toString")
    else:
      return (false, OTHER, "")
  of "at":
    if argsTypeC.len() == 0:
      return (true, IDENT, "grid::at")
    elif argsTypeC.len() == 2:
      var ftm_res = funcTypesMatch("ARRAY::@a" & "+" & INT & "->" & "@a", argsType.join("+"))
      if ftm_res[0] == false:
        return (false, OTHER, "grid::at")
      
      return (true, ftm_res[1], "grid::at")
    else:
      return (false, OTHER, "")
  of "readln":
    if argsTypeC.len() == 0:
      return (true, STRING, "grid::readln")
    else:
      return (false, OTHER, "")
  else:
    return (false, NIL, "NULL")

proc replaceSemicolon(parts: seq[codeParts], obj: seq[codeParts]): seq[codeParts] =
  if parts.len() == 0:
    return parts

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

proc makeInitValue(Type: string, test: bool, line: int): seq[codeParts] =
  var type_split = Type.split("::")

  case type_split[0]
  of INT:
    result = @[(INT, "0")]
  of FLOAT:
    result = @[(FLOAT, "0.0f")]
  of CHAR:
    result = @[(CHAR, "\'\'")]
  of STRING:
    result = @[(STRING, "\"\"")]
  of BOOL:
    result = @[(BOOL, "false")]
  of ARRAY:
    var convT = ""
    for i, t in type_split:
      if i != 0:
        convT.add("::")
      convT.add("T_" & t)
    result = @[(LPAREN, "("), (T_ARRAY, convT.conversionCppType(test, line)[1]), (LPAREN, ")"), (Type, "{}")]
  else:
    if typeExistenceCheck(type_split[0]):
      var ts = typeTable[type_split[0]].Type.split("+")
      result.add((LBRACE, "{"))
      for i, t in ts:
        if i != 0:
          result.add((OTHER, ","))
        result.add(t.makeInitValue(test, line))
      result.add((RBRACE, "}"))
    else:
      echoErrorMessage("当てはまらない型です", test, line)

proc makeVarDefine(node: Node, var_name: string, namespace: string, type_cp: codeParts, value: seq[codeParts], test: bool, mutable: bool, init: bool): (seq[codeParts], string) =
  var
    code: seq[codeParts]
    codeType: string
    types = node.token.Type.split("::")
    var_name_full: string = var_name
  
  if namespace != "":
    if identExistenceCheck(namespace)[0]:
      var_name_full = namespace & "." & var_name_full
    else:
      echoErrorMessage("\"" & namespace & "\"が存在しません", test, node.token.Line)
  
  if identExistenceCheck(var_name_full)[0]:
    echoErrorMessage("既に定義されています", test, node.token.Line)

  if types[0] == ARRAY:
    var types = node.token.Type.split("::")
    for i, tv in types:
      if i != 0:
        codeType.add("::")
      codeType.add(tv.removeT())
  else:
    codeType = type_cp[0].removeT()

  # if mutable == false:
  #   code.add((OTHER, "const"))
  code.add(type_cp)
  code.add((IDENT, var_name_full))
  if init:
    code.add((OTHER, "="))
    code.add(value)
  code.addSemicolon()

  if namespace == "":
    IdentInfo(
      Type:     codeType,
      init:     init,
      path:     nesting,
      mutable:  mutable,
      used:     false,
    ).identRegistration(var_name_full, nesting)
  else:
    identTable[namespace].member.add((var_name, IdentInfo(
      Type:     codeType,
      init:     init,
      path:     nesting,
      mutable:  mutable,
      used:     false,
    )))
  
  return (code, codeType)

proc makeCodeParts(node: Node, test: bool, dost: bool): (seq[codeParts], string) =
  var
    code: seq[codeParts]
    codeType: string
  
  case node.kind

  # リテラル
  of nkIntLiteral:
    if dost == false:
      echoErrorMessage("文の外でintリテラルを使用することはできません", test, node.token.Line)
    code.add((INT, node.token.Literal))
    code.addSemicolon()
    codeType = INT
  of nkFloatLiteral:
    if dost == false:
      echoErrorMessage("文の外でfloatリテラルを使用することはできません", test, node.token.Line)
    code.add((FLOAT, node.token.Literal & "f"))
    code.addSemicolon()
    codeType = FLOAT
  of nkBoolLiteral:
    if dost == false:
      echoErrorMessage("文の外でboolリテラルを使用することはできません", test, node.token.Line)
    if node.token.Literal == "True":
      code.add((BOOL, "true"))
      code.addSemicolon()
    elif node.token.Literal == "False":
      code.add((BOOL, "false"))
      code.addSemicolon()
    else:
      echoErrorMessage("無効なboolリテラルです", test, node.token.Line)
    codeType = BOOL
  of nkCharLiteral:
    if dost == false:
      echoErrorMessage("文の外でcharリテラルを使用することはできません", test, node.token.Line)
    code.add((CHAR, "\'" & node.token.Literal & "\'"))
    code.addSemicolon()
    codeType = CHAR
  of nkStringLiteral:
    if dost == false:
      echoErrorMessage("文の外でstringリテラルを使用することはできません", test, node.token.Line)
    code.add((STRING, "\"" & node.token.Literal & "\""))
    code.addSemicolon()
    codeType = STRING
  of nkArrayLiteral:
    if dost == false:
      echoErrorMessage("文の外でArrayリテラルを使用することはできません", test, node.token.Line)
    if node.child_nodes == @[]:
      code.add((LBRACE, "{"))
      code.add((RBRACE, "}"))
      code.addSemicolon()
      codeType = ARRAY
    else:
      var tmp_code: seq[codeParts]
      tmp_code.add((LBRACE, "{"))
      var eltype: string
      var loopCount = 0
      for arv in node.child_nodes[0].child_nodes:
        let elem = arv.makeCodeParts(test, dost)
        if loopCount == 0:
          eltype = elem[1]
          tmp_code.add(elem[0].replaceSemicolon(@[(OTHER, "")]))
        elif typePartMatch(elem[1], eltype)[0]:
          tmp_code.add((COMMA, ","))
          tmp_code.add(elem[0].replaceSemicolon(@[(OTHER, "")]))
        else:
          echoErrorMessage("配列内の要素の型が全て同じになっていません", test, node.token.Line)
        loopCount += 1
      tmp_code.add((RBRACE, "}"))
      tmp_code.addSemicolon()
      var literal_type = "T_" & ARRAY
      for ts in eltype.split("::"):
        literal_type.add("::" & "T_" & ts)
      code.add((OTHER, "("))
      code.add(conversionCppType(literal_type, test, node.token.Line))
      code.add((OTHER, ")"))
      code.add(tmp_code)
      codeType = ARRAY & "::" & eltype
  of nkNIl:
    code.add((NIL, "NULL"))
    code.addSemicolon()
    codeType = NIL
  of nkIntType:
    if node.child_nodes.len() == 1:
      var type_cp = node.token.Type.conversionCppType(test, node.token.Line)
      code.add(type_cp)
      code.add((INT, node.child_nodes[0].token.Literal))
      codeType = type_cp[0].removeT()
    elif node.child_nodes.len() == 2:
      var
        new_dost = true
        type_cp = node.token.Type.conversionCppType(test, node.token.Line)
        var_name = node.child_nodes[0].token.Literal
        value = node.child_nodes[1].makeCodeParts(test, new_dost)
      if type_cp[0].removeT() == value[1]:
        var mvd_res = makeVarDefine(node, var_name, "", type_cp, value[0], test, false, true)
        code.add(mvd_res[0])
        codeType = mvd_res[1]
      else:
        echoErrorMessage("指定している型と値の型が違います", test, node.token.Line)
    else:
      echoErrorMessage("不明なエラー", test, node.token.Line)
  of nkFloatType:
    if node.child_nodes.len() == 1:
      var type_cp = node.token.Type.conversionCppType(test, node.token.Line)
      code.add(type_cp)
      code.add((FLOAT, node.child_nodes[0].token.Literal))
      codeType = type_cp[0].removeT()
    elif node.child_nodes.len() == 2:
      var
        new_dost = true
        type_cp = node.token.Type.conversionCppType(test, node.token.Line)
        var_name = node.child_nodes[0].token.Literal
        value = node.child_nodes[1].makeCodeParts(test, new_dost)
      if type_cp[0].removeT() == value[1]:
        var mvd_res = makeVarDefine(node, var_name, "", type_cp, value[0], test, false, true)
        code.add(mvd_res[0])
        codeType = mvd_res[1]
      else:
        echoErrorMessage("指定している型と値の型が違います", test, node.token.Line)
    else:
      echoErrorMessage("不明なエラー", test, node.token.Line)
  of nkCharType:
    if node.child_nodes.len() == 1:
      var type_cp = node.token.Type.conversionCppType(test, node.token.Line)
      code.add(type_cp)
      code.add((CHAR, node.child_nodes[0].token.Literal))
      codeType = type_cp[0].removeT()
    elif node.child_nodes.len() == 2:
      var
        new_dost = true
        type_cp = node.token.Type.conversionCppType(test, node.token.Line)
        var_name = node.child_nodes[0].token.Literal
      var value = node.child_nodes[1].makeCodeParts(test, new_dost)
      if type_cp[0].removeT() == value[1]:
        var mvd_res = makeVarDefine(node, var_name, "", type_cp, value[0], test, false, true)
        code.add(mvd_res[0])
        codeType = mvd_res[1]
      else:
        echoErrorMessage("指定している型と値の型が違います", test, node.token.Line)
    else:
      echoErrorMessage("不明なエラー", test, node.token.Line)
  of nkStringType:
    if node.child_nodes.len() == 1:
      var type_cp = node.token.Type.conversionCppType(test, node.token.Line)
      code.add(type_cp)
      code.add((STRING, node.child_nodes[0].token.Literal))
      codeType = type_cp[0].removeT()
    elif node.child_nodes.len() == 2:
      var
        new_dost = true
        type_cp = node.token.Type.conversionCppType(test, node.token.Line)
        var_name = node.child_nodes[0].token.Literal
        value = node.child_nodes[1].makeCodeParts(test, new_dost)
      if type_cp[0].removeT() == value[1]:
        var mvd_res = makeVarDefine(node, var_name, "", type_cp, value[0], test, false, true)
        code.add(mvd_res[0])
        codeType = mvd_res[1]
      else:
        echoErrorMessage("指定している型と値の型が違います", test, node.token.Line)
    else:
      echoErrorMessage("不明なエラー", test, node.token.Line)
  of nkBoolType:
    if node.child_nodes.len() == 1:
      var type_name = node.token.Type.conversionCppType(test, node.token.Line)
      code.add(type_name)
      code.add((BOOL, node.child_nodes[0].token.Literal))
      codeType = type_name[0].removeT()
    elif node.child_nodes.len() == 2:
      var
        new_dost = true
        type_cp = node.token.Type.conversionCppType(test, node.token.Line)
        var_name = node.child_nodes[0].token.Literal
        value = node.child_nodes[1].makeCodeParts(test, new_dost)
      if type_cp[0].removeT() == value[1]:
        var mvd_res = makeVarDefine(node, var_name, "", type_cp, value[0], test, false, true)
        code.add(mvd_res[0])
        codeType = mvd_res[1]
      else:
        echoErrorMessage("指定している型と値の型が違います", test, node.token.Line)
    else:
      echoErrorMessage("不明なエラー", test, node.token.Line)
  of nkArrayType:
    if node.child_nodes.len() == 1:
      # ARRAYだけ特殊
      code.add(node.token.Type.conversionCppType(test, node.token.Line))
      code.add((ARRAY, node.child_nodes[0].token.Literal))
      let types = node.token.Type.split("::")
      for i, tv in types:
        if i != 0:
          codeType.add("::")
        codeType.add(tv.removeT())
    elif node.child_nodes.len() == 2:
      var
        new_dost = true
        type_cp = node.token.Type.conversionCppType(test, node.token.Line)
        var_name = node.child_nodes[0].token.Literal
        value = node.child_nodes[1].makeCodeParts(test, new_dost)
      if type_cp[0].removeT() == value[1]:
        var mvd_res = makeVarDefine(node, var_name, "", type_cp, value[0], test, false, true)
        code.add(mvd_res[0])
        codeType = mvd_res[1]
      else:
        echoErrorMessage("指定している型と値の型が違います", test, node.token.Line)
    else:
      echoErrorMessage("不明なエラー", test, node.token.Line)
  
  # ユーザー定義型
  of nkTypeIdent:
    if node.child_nodes.len() == 1:
      var type_name = node.token.Type.conversionCppType(test, node.token.Line)
      code.add(type_name)
      code.add((type_name[0].removeT(), node.child_nodes[0].token.Literal))
      codeType = type_name[0].removeT()
    elif node.child_nodes.len() == 2:
      var
        new_dost = true
        type_cp = node.token.Type.conversionCppType(test, node.token.Line)
        var_name = node.child_nodes[0].token.Literal
        value = node.child_nodes[1].makeCodeParts(test, new_dost)
      if type_cp[0].removeT() == value[1]:
        var mvd_res = makeVarDefine(node, var_name, "", type_cp, value[0], test, false, true)
        for m in typeTable[node.token.Type.removeT()].member:
          discard makeVarDefine(node, m[0], var_name, m[1].Type.conversionCppType(test, node.token.Line), @[], test, false, true)
        code.add(mvd_res[0])
        codeType = mvd_res[1]
      else:
        echoErrorMessage("指定している型と値の型が違います", test, node.token.Line)
    else:
      echoErrorMessage("不明なエラー", test, node.token.Line)

  # 複合リテラル
  of nkCompoundLiteral:
    var
      struct_type = node.child_nodes[0].token.Literal.conversionCppType(test, node.token.Line)
      lit: (seq[codeParts], string)
      lit_types: seq[string]
    
    code.add((OTHER, "("))
    code.add(struct_type)
    code.add((OTHER, ")"))

    code.add((LBRACE, "{"))
    for i, n in node.child_nodes[1].child_nodes:
      if i != 0:
        code.add((OTHER, ","))
      lit = n.makeCodeParts(test, dost)
      code.add(lit[0].replaceSemicolon(@[(OTHER, "")]))
      lit_types.add(lit[1])
    code.add((RBRACE, "}"))
    code.addSemicolon()

    if typeTable[node.child_nodes[0].token.Literal].Type != lit_types.join("+"):
      echoErrorMessage("指定された型と合いません", test, node.token.Line)
    else:
      codeType = node.child_nodes[0].token.Literal

  # コメント
  of nkComment:
    codeType = COMMENTBEGIN

  # 名前
  of nkIdent:
    var check_res = identExistenceCheck(node.token.Literal)

    if check_res[0]:
      code.add((IDENT, node.token.Literal))
      codeType = (identTable[node.token.Literal].Type)
      identTable[node.token.Literal].used = true
    elif check_res[1] != IdentInfo():
      code.add((IDENT, node.token.Literal))
      codeType = (check_res[1].Type)
      identTable[node.token.Literal.split(".")[0]].used = true
    else:
      let ic = node.token.Literal.conversionCppFunction(@[])
      if ic[1] == NIL:
        echoErrorMessage("\"" & node.token.Literal & "\"が定義されていません", test, node.token.Line)
      code.add((ic[1], ic[2]))
      codeType = ic[1]

  # main文
  of nkMainStatement:
    if dost == false:
      code.add((OTHER, "\n"))
    
    var new_dost = true
    let di = node.child_nodes[0].makeCodeParts(test, new_dost)
    if identExistenceCheck(di[0][1][1])[0]:
      echoErrorMessage("既に定義されています", test, node.token.Line)
    # echo di
    code.add((OTHER, di[0][0].Code))
    code.add(di[0][1])
    if node.child_nodes[1].child_nodes == @[]:
      IdentInfo(
        Type:    NIL & "+" & di[1],
        init:    true,
        path:    nesting,
        mutable: false,
        used:  false,
      ).identRegistration(di[0][1][1], nesting)
    else:
      var argsType: seq[string]
      for parameter in node.child_nodes[1].child_nodes:
        argsType.add(parameter.token.Type.removeT())
      IdentInfo(
        Type:    argsType.join("+") & "+" & di[1],
        init:    true,
        path:    nesting,
        mutable: false,
        used:  false,
      ).identRegistration(di[0][1][1], nesting)
    var origin = nesting
    nestingIncrement()
    if node.child_nodes[1].child_nodes == @[]:
      code.add((OTHER, "()"))
      code.add((OTHER, "{"))
      for statement in node.child_nodes[2].child_nodes:
        if statement.kind == nkReturnStatement:
          let st = statement.makeCodeParts(test, new_dost)
          if typePartMatch(st[1], di[1])[0]:
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
        IdentInfo(
          Type:    pr[1],
          init:    true,
          path:    nesting,
          mutable: false,
          used:  false,
        ).identRegistration(parameter.child_nodes[0].token.Literal, nesting)
      code.add((OTHER, ")"))
      code.add((OTHER, "{"))
      for statement in node.child_nodes[2].child_nodes:
        if statement.kind == nkReturnStatement:
          let st = statement.makeCodeParts(test, new_dost)
          if typePartMatch(st[1], di[1])[0]:
            code.add(st[0])
          else:
            echoErrorMessage("指定している型と返り値の型が違います", test, node.token.Line)
        else:
          code.add(statement.makeCodeParts(test, new_dost)[0])
    # nestingをリセット
    nestingReset(origin, test)
    code.add((OTHER, "}"))
    codeType = MAIN

  # def文
  of nkDefineStatement:
    if dost:
      echoErrorMessage("文の中で関数を定義することはできません", test, node.token.Line)
    else:
      code.add((OTHER, "\n"))
    var new_dost = true

    let di = node.child_nodes[0].makeCodeParts(test, new_dost)
    if identExistenceCheck(di[0][1][1])[0]:
      echoErrorMessage("既に定義されています", test, node.token.Line)
    # echo di
    code.add(di[0][0])
    code.add(di[0][1])
    if node.child_nodes[1].child_nodes == @[]:
      IdentInfo(
        Type:    NIL & "->" & di[1],
        init:    true,
        path:    nesting,
        mutable: false,
        used:  false,
      ).identRegistration(di[0][1][1], nesting)
    else:
      var argsType: seq[string]
      for parameter in node.child_nodes[1].child_nodes:
        argsType.add(parameter.token.Type.removeT())
      IdentInfo(
        Type:    argsType.join("+") & "->" & di[1],
        init:    true,
        path:    nesting,
        mutable: false,
        used:  false,
      ).identRegistration(di[0][1][1], nesting)
    
    var origin = nesting
    nestingIncrement()
    var return_flag = false

    if node.child_nodes[1].child_nodes == @[]:
      code.add((OTHER, "()"))
      code.add((OTHER, "{"))
      for statement in node.child_nodes[2].child_nodes:
        if statement.kind == nkReturnStatement:
          return_flag = true
          let st = statement.makeCodeParts(test, new_dost)
          if typePartMatch(st[1], di[1])[0]:
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
        IdentInfo(
          Type:    pr[1],
          init:    true,
          path:    nesting,
          mutable: false,
          used:    false,
        ).identRegistration(parameter.child_nodes[0].token.Literal, nesting)
      code.add((OTHER, ")"))
      code.add((OTHER, "{"))
      for statement in node.child_nodes[2].child_nodes:
        if statement.kind == nkReturnStatement:
          return_flag = true
          let st = statement.makeCodeParts(test, new_dost)
          if typePartMatch(st[1], di[1])[0]:
            code.add(st[0])
          else:
            echoErrorMessage("指定している型と返り値の型が違います", test, node.token.Line)
        else:
          code.add(statement.makeCodeParts(test, new_dost)[0])
    
    if return_flag == false:
      # TODO 警告メッセージを作る
      code.add((RETURN, "return"))
      code.add(makeInitValue(di[1], test, node.token.Line))
      code.addSemicolon()

    # nestingをリセット
    nestingReset(origin, test)
    code.add((OTHER, "}"))
    codeType = DEFINE

  # return文
  of nkReturnStatement:
    if dost == false:
      echoErrorMessage("文の外でreturn文を使用することはできません", test, node.token.Line)
    if node.child_nodes == @[]:
      echoErrorMessage("式がありません", test, node.token.Line)
    
    code.add((OTHER, "return"))
    code.add((OTHER, "("))
    let r = node.child_nodes[0].makeCodeParts(test, dost)
    code.add(r[0].replaceSemicolon(@[(OTHER, "")]))
    code.add((OTHER, ")"))
    code.addSemicolon()
    codeType = r[1]

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
    var lt: string
    if node.child_nodes.len() == 2:
      let l = node.child_nodes[0].makeCodeParts(test, dost)
      code.add(l[0])
      lt = l[1]
      nestingIncrement()
      if identExistenceCheck(l[0][1][1])[0]:
        echoErrorMessage("既に定義されています", test, node.token.Line)
      IdentInfo(
        Type:    lt,
        init:    true,
        path:    nesting,
        mutable: false,
        used:  false,
      ).identRegistration(l[0][1][1], nesting)
      codeType = l[1]
      
      code.add((COLON, ":"))

      let r = node.child_nodes[1].makeCodeParts(test, dost)
      var r_s = r[1].split("ARRAY::")
      var r_tail = r_s[1..r_s.len()-1]
      if lt == r_tail.join():
        code.add(r[0])
      else:
        echoErrorMessage("指定している型と値の型が違います", test, node.token.Line)
    else:
      echoErrorMessage("式がありません", test, node.token.Line)

  # 配列の添字
  of nkAccessElement:
    if node.child_nodes.len() == 2:
      let l = node.child_nodes[0].makeCodeParts(test, dost)
      let r = node.child_nodes[1].makeCodeParts(test, dost)
      let rv = r[0].replaceSemicolon(@[(OTHER, "")])
      let ls = l[1].split("::")
      if r[1] != INT:
        echoErrorMessage("添字の型が間違っています", test, node.token.Line)
      elif ls[0] != ARRAY:
        echoErrorMessage("配列ではありません", test, node.token.Line)
      else:
        code.add(l[0].replaceSemicolon(@[(OTHER, "")]))
        code.add((OTHER, "["))
        code.add(rv)
        code.add((OTHER, "]"))
        code.addSemicolon()
        codeType = ls[1..ls.len()-1].join("::")
    else:
      echoErrorMessage("添字がありません", test, node.token.Line)

  # 代入式
  of nkAssignExpression:
    var lt, rt: string
    if node.child_nodes.len() == 2:
      # 値を代入しようとしている変数のチェック
      # 未定義の変数も扱うので少し特殊
      var lmc = node.child_nodes[0].token.Literal
      var lmc_split = lmc.split(".")
      
      if identTable.contains(lmc_split[0]) == false:
        echoErrorMessage("\"" & lmc & "\"が定義されていません", test, node.token.Line)
      elif identTable[lmc_split[0]].mutable == false and identTable[lmc_split[0]].init == true:
        echoErrorMessage("代入しようとしている変数がイミュータブルです", test, node.token.Line)
      else:
        if lmc_split.len() != 1:
          var search_res = memberSearch(identTable[lmc_split[0]].member, lmc_split[1..lmc_split.len()-1].join("."))
          if search_res[0]:
            identTable[lmc_split[0]].init = true
            code.add((IDENT, lmc))
          else:
            echoErrorMessage("\"" & lmc & "\"が定義されていません", test, node.token.Line)
        else:
          identTable[lmc_split[0]].init = true
          code.add((IDENT, lmc_split[0]))
      lt = identTable[lmc].Type

      code.add((OTHER, "="))
      let r = node.child_nodes[1].makeCodeParts(test, dost)
      code.add(r[0])
      rt = r[1]
    else:
      echoErrorMessage("オペランドがありません", test, node.token.Line)
    code.addSemicolon()
    if typePartMatch(lt, rt)[0]:
      codeType = lt
    else:
      echoErrorMessage("オペランドの型がそれぞれ違います", test, node.token.Line)

  # 前置
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
    let iec = identExistenceCheck(funcName)[0]
    if iec:
      let ftm = funcTypesMatch(identTable[funcName].Type, argsType.join("+"))
      if ftm[0]:
        code.add((IDENT, funcName))
        codeType = ftm[1]
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
          echoErrorMessage("\"" & funcName & "\"が定義されていません", test, node.token.Line)
    
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

    if node.child_nodes[1].child_nodes.len() != 2:
      echoErrorMessage("引数の数が合いません", test, node.token.Line)
    elif node.child_nodes[1].child_nodes[1].kind != nkCallExpression:
      echoErrorMessage("第二引数が正しくありません", test, node.token.Line)

    let func_name = node.child_nodes[1].child_nodes[1].child_nodes[0].token.Literal
    var cpp_func_name = ""
    var func_result_type = ""
    let array_CandT = node.child_nodes[1].child_nodes[0].makeCodeParts(test, dost)
    let array_content = array_CandT[0].replaceSemicolon(@[(OTHER, "")])
    let array_type = array_CandT[1]
    let array_type_split = array_type.split("::")
    var fn = node.child_nodes[1].child_nodes[1]
    
    var func_arg_types: seq[string]
    for nodes in fn.child_nodes[1].child_nodes:
      func_arg_types.add(nodes.token.Type)

    if array_type_split[0] != ARRAY:
      echoErrorMessage("第一引数の型が正しくありません", test, node.token.Line)

    let i_node = Node(
      kind:        nkIdent,
      token:       Token(Type: IDENT, Literal: "_i", Line: node.token.Line),
      child_nodes: @[],
    )
    var original_nesting = nesting
    nestingIncrement()
    
    fn.child_nodes[1].child_nodes = @[i_node] & fn.child_nodes[1].child_nodes

    let ccf = conversionCppFunction(func_name, array_type_split[1..array_type_split.len()-1].join("::") & func_arg_types)
    if ccf[0]:
      cpp_func_name = ccf[2]
      func_result_type = ccf[1]
    else:
      if identExistenceCheck(func_name)[0] == false:
        if ccf[1] == NIL:
          echoErrorMessage("存在しない関数です", test, node.token.Line)
        else:
          echoErrorMessage("第二引数の関数の引数が正しくありません", test, node.token.Line)
      else:
        let ftm = funcTypesMatch(identTable[func_name].Type, array_type_split[1..array_type_split.len()-1].join("::") & func_arg_types.join("+"))
        if ftm[0]:
          cpp_func_name = func_name
          func_result_type = ftm[1]
        else:  
          echoErrorMessage("第二引数の関数の引数が正しくありません", test, node.token.Line)

    if func_result_type.split("::") != array_type_split[1..array_type_split.len()-1]:
      echoErrorMessage("第二引数の関数の返り値が正しくありません", test, node.token.Line)

    code.add((IDENT, "grid::map"))
    code.add((OTHER, "("))
    code.add(array_content)
    code.add((OTHER, ","))
    code.add((OTHER, "[]"))
    code.add((OTHER, "("))
    let ident = Node(
      kind:        nkArrayType,
      token:       Token(Type: "T_" & array_type_split[1..array_type_split.len()-1].join("::T_"), Literal:"{"),
      child_nodes: @[Node(
        kind:        nkIdent,
        token:       Token(Type: IDENT, Literal: "_i"),
        child_nodes: @[],
      )],
    )
    IdentInfo(
      Type:     array_type_split[1..array_type_split.len()-1].join("::"),
      init:     true,
      path:     nesting,
      mutable:  false,
      used:     false,
    ).identRegistration("_i", nesting)
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

    nestingReset(original_nesting, test)
    codeType = array_type

  # mut文
  of nkMutStatement:
    if dost == false:
      echoErrorMessage("文の外でmut文を使用することはできません", test, node.token.Line)
    var new_dost = true

    var original_nesting = nesting
    nestingIncrement()

    code.add((OTHER, "{"))
    for statement in node.child_nodes[0].child_nodes:
      var type_cp = statement.token.Type.conversionCppType(test, node.token.Line)
      var var_name = statement.child_nodes[0].token.Literal
      var value = statement.child_nodes[1].makeCodeParts(test, new_dost)
      if type_cp[0].removeT() == value[1]:
        var mvd_res = makeVarDefine(node, var_name, "", type_cp, value[0], test, true, true)
        code.add(mvd_res[0])
        codeType = mvd_res[1]
      else:
        echoErrorMessage("指定している型と値の型が違います", test, node.token.Line)
    
    for statement in node.child_nodes[1].child_nodes:
      code.add(statement.makeCodeParts(test, new_dost)[0])
    
    code.add((OTHER, "}"))

    nestingReset(original_nesting, test)

  # later文
  of nkLaterStatement:
    if dost == false:
      code.add((OTHER, "\n"))

    var
      new_dost = true
      type_cp: codeParts
      var_name: string
      mvd_res: (seq[codeParts], string)
    for statement in node.child_nodes:
      type_cp = statement.token.Type.conversionCppType(test, node.token.Line)
      var_name = statement.child_nodes[0].token.Literal
      if typeExistenceCheck(statement.token.Type):
        for m in typeTable[statement.token.Type].member:
          discard makeVarDefine(node, m[0], var_name, m[1].Type.conversionCppType(test, node.token.Line), @[], test, false, false)
      mvd_res = makeVarDefine(node, var_name, "", type_cp, @[], test, false, false)
      code.add(mvd_res[0].replaceSemicolon(@[(OTHER, "")]))
      code.add((OTHER, "="))
      code.add(makeInitValue(type_cp[0].removeT(), test, node.token.Line))
      code.addSemicolon()
      codeType = mvd_res[1]
  
  # struct文
  of nkStruct:
    if dost == false:
      code.add((OTHER, "\n"))

    var
      new_dost = true
      original_nesting = nesting
      struct_name = node.child_nodes[0].token.Literal
    nestingIncrement()
    
    code.add((OTHER, "typedef"))
    code.add((OTHER, "struct"))
    code.add((OTHER, "{"))

    var
      member_infos: seq[(string, TypeInfo)]
      member_types: seq[string]
      type_cp: codeParts
      member_name: string
      mvd_res: (seq[codeParts], string)
    for statement in node.child_nodes[1].child_nodes:
      type_cp = statement.token.Type.conversionCppType(test, node.token.Line)
      member_name = statement.child_nodes[0].token.Literal
      member_infos.add((member_name, TypeInfo(
        Type:    type_cp[0],
        member:  @[],
        code:    type_cp[1],
        path:    nesting,
        mutable: false,
        used:    false,
      )))
      member_types.add(type_cp.Type.removeT())
      mvd_res = makeVarDefine(node, member_name, "", type_cp, @[], test, false, false)
      code.add(mvd_res[0].replaceSemicolon(@[(OTHER, "")]))
      code.addSemicolon()

    nestingReset(original_nesting, test)
    TypeInfo(
      Type:    member_types.join("+"),
      member:  member_infos,
      code:    struct_name,
      path:    nesting,
      mutable: false,
      used:    false,
    ).typeRegistration(struct_name, nesting)
    codeType = member_types.join("+")

    code.add((OTHER, "} " & struct_name & " ;"))

  # if文
  of nkIfStatement:
    if dost == false:
      echoErrorMessage("文の外でif文を使用することはできません", test, node.token.Line)
    var new_dost = true

    var original_nesting = nesting
    nestingIncrement()
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

    nestingReset(original_nesting, test)
    if node.child_nodes.len() == 3:
      let ar = node.child_nodes[2].makeCodeParts(test, new_dost)
      code.add(ar[0])
    codeType = sr[1]

  # elif文
  of nkElifStatement:
    if dost == false:
      echoErrorMessage("文の外でelif文を使用することはできません", test, node.token.Line)
    var new_dost = true

    var original_nesting = nesting
    nestingIncrement()
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

    nestingReset(original_nesting, test)
    if node.child_nodes.len() == 3:
      let ar = node.child_nodes[2].makeCodeParts(test, new_dost)
      code.add(ar[0])
    codeType = sr[1]

  # else文
  of nkElseStatement:
    if dost == false:
      echoErrorMessage("文の外でelif文を使用することはできません", test, node.token.Line)
    var new_dost = true

    var original_nesting = nesting
    nestingIncrement()
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
    nestingReset(original_nesting, test)
    codeType = sr[1]
  
  # if式
  of nkIfExpression:
    if dost == false:
      echoErrorMessage("文の外でif式を使用することはできません", test, node.token.Line)

    code.add((OTHER, "("))
    code.add(node.child_nodes[0].makeCodeParts(test, dost)[0].replaceSemicolon(@[(OTHER, "")]))
    code.add((OTHER, "?"))
    var sr = node.child_nodes[1].makeCodeParts(test, dost)
    code.add(sr[0].replaceSemicolon(@[(OTHER, "")]))
    let ar = node.child_nodes[2].makeCodeParts(test, dost)
    if typePartMatch(ar[1], sr[1])[0]:
      code.add((OTHER, ":"))
      code.add(ar[0].replaceSemicolon(@[(OTHER, "")]))
      codeType = sr[1]
      code.add((OTHER, ")"))
      code.addSemicolon()
    else:
      echoErrorMessage("返り値の型が異なっています", test, node.token.Line)

  # else式
  of nkElseExpression:
    if dost == false:
      echoErrorMessage("文の外でelse式を使用することはできません", test, node.token.Line)

    var sr = node.child_nodes[0].makeCodeParts(test, dost)
    code.add(sr[0].replaceSemicolon(@[(OTHER, "")]))
    codeType = sr[1]

  # for文
  of nkForStatement:
    if dost == false:
      echoErrorMessage("文の外でfor文を使用することはできません", test, node.token.Line)
    var new_dost = true

    let origin = nesting
    code.add((OTHER, "for"))
    code.add((OTHER, "("))
    code.add(node.child_nodes[0].makeCodeParts(test, new_dost)[0].replaceSemicolon(@[(OTHER, "")]))
    code.add((OTHER, ")"))
    code.add((OTHER, "{"))
    var sr: (seq[codeParts], string)
    for i, statement in node.child_nodes[1].child_nodes:
      sr = statement.makeCodeParts(test, new_dost)
      code.add(sr[0])
    nestingReset(origin, test)
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
    if part.Code == "":
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
    elif part.Type == OTHER and part.Code.contains("}"):
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