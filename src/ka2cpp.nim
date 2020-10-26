import ka2token, ka2node, ka2token, ka2error
import strutils, tables

#------↓仮↓------

type codeParts = tuple
  Type: string
  Code: string

type IdentInfo* = ref object of RootObj
  Type*:        string
  contents*:    seq[codeParts]
  path*:        string
  mutable*:     bool
  arrayLength*: int

var
  identTable = initTable[string, IdentInfo]()
  blockPath = "0"

proc initTables*() =
  identTable = initTable[string, IdentInfo]()
  blockPath = "0"

proc blockPathMatch(target: string): bool =
  let bps = blockPath.split("-")
  let tps = target.split("-")
  
  # # 後で消す
  # echo tps[0..tps.len()-2]
  # echo "pathのチェック"

  if tps != @[]:
    for i, tp in tps[0..tps.len()-2]:
      if tp != bps[i]:
        return false
  
  return true

proc nextPath(): string =
  let bps = blockPath.split("-")
  let next = bps[bps.len()-1].parseInt() + 1
  let res = bps[0..bps.len()-2] & $next

  return res.join("-")

proc searchCodeParts(codePartsList: seq[codeParts], target: string): seq[codeParts] =
  for cp in codePartsList:
    if cp.Type == target:
      result.add(cp)

proc identExistenceCheck(ident: string): bool =
  if identTable.contains(ident):
    if identTable[ident].path.blockPathMatch():
      return true
  
  return false

proc typeMatch(type1: string, type2: string): (bool, string) =
  # echo type1 & "___" & type2

  var
    typeList1: seq[seq[string]]
    typeList2: seq[seq[string]]

  for t1s in type1.split("::"):
    typeList1.add(@[t1s.split("|")])
  for t2s in type2.split("::"):
    typeList2.add(@[t2s.split("|")])

  # echo $typeList1 & "________" & $typeList2

  var
    typeFlow: string
    typeCandidacies: seq[string]

  for i, t1ss in typeList1:
    for t2ss in typeList2[i]:
      for t1sss in t1ss:
        if t1sss == t2ss:
          typeCandidacies.add(t1sss)
    if typeCandidacies != @[]:
      if i != 0:
        typeFlow.add("::")
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

proc funcTypesMatch(funcType: string, argsType: string): (bool, string, string) =
  var fnTs = funcType.funcTypeSplit(">>")
  let res = typeMatch(fnTs[1], argsType)
  
  if fnTs[0] == false or res[0] == false or argsType == "":
    return (false, "", fnTs[1])
  
  return (res[0], res[1], fnTs[2])

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
  var argsTypeC = argsType
  # for _ in [argsTypeC.len()-1..2]:
  #   argsTypeC.add("")
  case fn
  of "plus":
    let fmr1 = funcTypesMatch(number_t & ">>" & number_t & ">>" & number_t, argsTypeC[0])
    if fmr1[0]:
      if argsTypeC.len()-1 != 0:
        let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
        return (fmr2[0], fmr2[1], "_k_add")
      else:
        return (true, number_t & ">>" & number_t, "_k_add")
    else:
      return (true, number_t & ">>" & number_t & ">>" & number_t, "_k_add")
  of "minu":
    let fmr1 = funcTypesMatch(number_t & ">>" & number_t & ">>" & number_t, argsTypeC[0])
    if fmr1[0]:
      if argsTypeC.len()-1 != 0:
        let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
        return (fmr2[0], fmr2[1], "_k_sub")
      else:
        return (true, number_t & ">>" & number_t, "_k_sub")
    else:
      return (true, number_t & ">>" & number_t & ">>" & number_t, "_k_sub")
  of "mult":
    let fmr1 = funcTypesMatch(number_t & ">>" & number_t & ">>" & number_t, argsTypeC[0])
    if fmr1[0]:
      if argsTypeC.len()-1 != 0:
        let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
        return (fmr2[0], fmr2[1], "_k_mul")
      else:
        return (true, number_t & ">>" & number_t, "_k_mul")
    else:
      return (true, number_t & ">>" & number_t & ">>" & number_t, "_k_mul")
  of "divi":
    let fmr1 = funcTypesMatch(number_t & ">>" & number_t & ">>" & number_t, argsTypeC[0])
    if fmr1[0]:
      if argsTypeC.len()-1 != 0:
        let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
        return (fmr2[0], fmr2[1], "_k_div")
      else:
        return (true, number_t & ">>" & number_t, "_k_div")
    else:
      return (true, number_t & ">>" & number_t & ">>" & number_t, "_k_div")
  of "puts":
    let fmr1 = funcTypesMatch(anything_t & ">>" & NIL, argsTypeC[0])
    if fmr1[0]:
      return (fmr1[0], NIL, "_k_puts")
    else:
      return (true, anything_t & ">>" & NIL, "_k_puts")
  of "len":
    let fmr1 = funcTypesMatch(ARRAY & "::" & anything_t & ">>" & INT, argsTypeC[0])
    if fmr1[0]:
      return (fmr1[0], INT, "_k_len")
    else:
      return (true, ARRAY & "::" & anything_t & ">>" & INT, "_k_len")
  of "join":
    let fmr1 = funcTypesMatch("ARRAY" & "::" & anything_t & ">>" & "ARRAY" & "::" & anything_t & ">>" & "ARRAY" & "::" & anything_t, argsTypeC[0])
    if fmr1[0]:
      if argsTypeC.len()-1 != 0:
        let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
        return (fmr2[0], fmr2[1], "_k_join")
      else:
        return (true, "ARRAY" & "::" & anything_t & ">>" & "ARRAY" & "::" & anything_t, "_k_join")
    else:
      return (true, "ARRAY" & "::" & anything_t & ">>" & "ARRAY" & "::" & anything_t & ">>" & "ARRAY" & "::" & anything_t, "_k_join")
  else:
    return (false, NIL, "NULL")

proc removeT(Type: string): string =
  if Type[0] == 'T' and Type[1] == '_':
    return Type[2..Type.len()-1]
  else:
    return Type

proc addSemicolon(parts: var seq[codeParts]) =
  let tail = parts[parts.len()-1]
  if tail.Type != SEMICOLON:
    parts.add((SEMICOLON, ";"))

proc replaceSemicolon(parts: seq[codeParts], obj: seq[codeParts]): seq[codeParts] =
  let tail = parts[parts.len()-1]
  if tail.Type[0] == '@':
    return replaceSemicolon(parts[0..parts.len()-2], @[parts[parts.len()-1]] & obj)
  elif tail.Type == SEMICOLON:
    return parts[0..parts.len()-2] & obj
  else:
    return parts

proc addIndent(code: var string, indent: int) =
  for i in 0..indent:
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
    code.add((FLOAT, node.token.Literal))
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
  #     echoErrorMessage(13, test)
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
          echoErrorMessage(0, test)
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
      echoErrorMessage(1, test)
  of nkFloatType:
    if node.child_nodes != @[]:
      code.add(node.token.Type.conversionCppType())
      code.add((FLOAT, node.child_nodes[0].token.Literal))
      codeType = FLOAT
    else:
      echoErrorMessage(1, test)
  of nkCharType:
    if node.child_nodes != @[]:
      code.add(node.token.Type.conversionCppType())
      code.add((CHAR, node.child_nodes[0].token.Literal))
      codeType = CHAR
    else:
      echoErrorMessage(1, test)
  of nkStringType:
    if node.child_nodes != @[]:
      code.add(node.token.Type.conversionCppType())
      code.add((STRING, node.child_nodes[0].token.Literal))
      codeType = STRING
    else:
      echoErrorMessage(1, test)
  of nkBoolType:
    if node.child_nodes != @[]:
      code.add(node.token.Type.conversionCppType())
      code.add((BOOL, node.child_nodes[0].token.Literal))
      codeType = BOOL
    else:
      echoErrorMessage(1, test)
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
      echoErrorMessage(1, test)
  of nkFunctionType:
    if node.child_nodes != @[]:
      code.add((T_FUNCTION, "auto"))
      code.add((FUNCTION, node.child_nodes[0].token.Literal))
      codeType = FUNCTION
    else:
      echoErrorMessage(1, test)

  # 名前
  of nkIdent:
    if identExistenceCheck(node.token.Literal):
      code.add((IDENT, node.token.Literal))
      codeType = identTable[node.token.Literal].Type
    else:
      let ic = node.token.Literal.conversionCppFunction(@[""])
      if ic[0]:
        code.add((ic[1], ic[2]))
        codeType = ic[1]
      else:
        echoErrorMessage(2, test)

  # 【】
  # of nkMapFunction:
  #   code.add((IDENT, "_k_map"))
  #   codeType = IDENT
  
  # let文
  of nkLetStatement:
    code.add((OTHER, "const"))
    let li = node.child_nodes[0].makeCodeParts(test)
    let lv = node.child_nodes[1].makeCodeParts(test)
    # echo li[1] & "___" & lv[1]
    if li[1] == lv[1]:
      if identExistenceCheck(li[0][1][1]):
        echoErrorMessage(3, test)
      code.add(li[0])
      code.add((OTHER, "="))
      code.add(lv[0].replaceSemicolon(@[(OTHER, "")]))
      code.addSemicolon()
      blockPath = nextPath()
      identTable[li[0][1][1]] = IdentInfo(
        Type: li[1],
        contents: lv[0],
        path: blockPath,
        mutable: false,
      )
      # TODO: 最悪
      if li[1].startsWith("ARRAY"):
        var ats = lv[0].searchCodeParts("@ARRAYLENGTH")
        identTable[li[0][1][1]].arrayLength = ats[ats.len()-1].Code.parseInt()
    else:
      echoErrorMessage(4, test)
  
  # mut文
  of nkMutStatement:
    let li = node.child_nodes[0].makeCodeParts(test)
    let lv = node.child_nodes[1].makeCodeParts(test)
    if li[1] == lv[1]:
      if identExistenceCheck(li[0][1][1]):
        echoErrorMessage(3, test)
      code.add(li[0])
      code.add((OTHER, "="))
      code.add(lv[0])
      code.addSemicolon()
      blockPath = nextPath()
      identTable[li[0][1][1]] = IdentInfo(
        Type: li[1],
        contents: lv[0],
        path: blockPath,
        mutable: true,
      )
      # TODO: 最悪
      if li[1].startsWith("ARRAY"):
        var ats = lv[0].searchCodeParts("@ARRAYLENGTH")
        identTable[li[0][1][1]].arrayLength = ats[ats.len()-1].Code.parseInt()
    else:
      echoErrorMessage(4, test)

  # def文
  of nkDefineStatement:
    code.add((AUTO, "auto"))
    let di = node.child_nodes[0].makeCodeParts(test)
    if identExistenceCheck(di[0][1][1]):
      echoErrorMessage(3, test)
    code.add(di[0][1])
    code.add((EQUAL, "="))
    if node.child_nodes[1].child_nodes == @[]:
      identTable[di[0][1][1]] = IdentInfo(
        Type: NIL & ">>" & di[1],
        path: blockPath,
        mutable: false,
      )
    else:
      var argsType: seq[string]
      for parameter in node.child_nodes[1].child_nodes:
        argsType.add(parameter.token.Type.removeT())
      identTable[di[0][1][1]] = IdentInfo(
        Type: argsType.join("::") & ">>" & di[1],
        path: blockPath,
        mutable: false,
      )
    let obp = blockPath
    blockPath.add("-0")
    if node.child_nodes[1].child_nodes == @[]:
      code.add((OTHER, "[]"))
      code.add((OTHER, "()"))
      code.add((OTHER, "{"))
      for statement in node.child_nodes[2].child_nodes:
        if statement.kind == nkReturnStatement:
          let st = statement.makeCodeParts(test)
          if typeMatch(st[1], di[1])[0]:
            code.add(st[0])
          else:
            echoErrorMessage(5, test)
        else:
          code.add(statement.makeCodeParts(test)[0])
      code.add((OTHER, "}"))
      code.addSemicolon()
    else:
      var arg: string = ""
      for i, parameter in node.child_nodes[1].child_nodes:
        let pr = parameter.makeCodeParts(test)
        code.add((OTHER, "[" & arg & "]"))
        code.add((OTHER, "("))
        code.add(pr[0])
        code.add((OTHER, ")"))
        arg = parameter.child_nodes[0].token.Literal
        blockPath = nextPath()
        identTable[arg] = IdentInfo(
          Type: pr[1],
          path: blockPath,
        )
        code.add((OTHER, "{"))
        if i != node.child_nodes[1].child_nodes.len()-1:
          code.add((RETURN, "return"))
      for statement in node.child_nodes[2].child_nodes:
        if statement.kind == nkReturnStatement:
          let st = statement.makeCodeParts(test)
          if typeMatch(st[1], di[1])[0]:
            code.add(st[0])
          else:
            echoErrorMessage(5, test)
        else:
          code.add(statement.makeCodeParts(test)[0])
      for _ in node.child_nodes[1].child_nodes:
        code.add((OTHER, "}"))
        code.addSemicolon()
    blockPath = obp
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
      echoErrorMessage(6, test)
  
  # 中置
  of nkInfixExpression:
    var 
      l: (seq[codeParts], string)
      r: (seq[codeParts], string)
    if node.child_nodes.len() != 2:
      echoErrorMessage(7, test)
    l = node.child_nodes[0].makeCodeParts(test)
    r = node.child_nodes[1].makeCodeParts(test)
    if l[1] == r[1]:
      let oc = node.token.Literal.conversionCppOperator(@[l[1], r[1]])
      if oc[0] == false:
        echoErrorMessage(8, test)
      code.add(((OTHER, "(")))
      code.add(l[0].replaceSemicolon(@[(OTHER, "")]))
      code.add((node.token.Type, oc[2]))
      code.add(r[0].replaceSemicolon(@[(OTHER, "")]))
      code.add(((OTHER, ")")))
      code.addSemicolon()
      codeType = oc[1]
    else:
      echoErrorMessage(9, test)
  
  # Generator
  of nkGenerator:
    # TODO: 型のチェック
    var lt: string
    if node.child_nodes.len() == 2:
      let l = node.child_nodes[0].makeCodeParts(test)
      code.add(l[0])
      lt = l[1]
      blockPath.add("-0")
      if identExistenceCheck(l[0][1][1]):
        echoErrorMessage(3, test)
      identTable[l[0][1][1]] = IdentInfo(
        Type: lt,
        path: blockPath,
      )
      codeType = l[1]
      
      code.add((COLON, ":"))

      let r = node.child_nodes[1].makeCodeParts(test)
      if lt == r[1].funcTypeSplit("ARRAY::")[2]:
        code.add(r[0])
      else:
        echoErrorMessage(4, test)
    else:
      echoErrorMessage(6, test)

  # パイプライン演算子
  of nkPipeExpression:
    if node.child_nodes.len() == 2:  
      if node.child_nodes[1].kind == nkCallExpression:
        # 右側の関数の引数の先頭に左の値を追加
        let rightArgs = node.child_nodes[1].child_nodes[1].child_nodes
        let leftValue = node.child_nodes[0]
        node.child_nodes[1].child_nodes[1].child_nodes = leftValue & rightArgs
        let r = node.child_nodes[1].makeCodeParts(test)
        code.add(r[0])
        codeType = r[1]
      else:
        echoErrorMessage(14, test)
    else:
      echoErrorMessage(7, test)

  # 配列の要素へのアクセス
  of nkAccessElement:
    if node.child_nodes.len() == 2:
      let l = node.child_nodes[0].makeCodeParts(test)
      let r = node.child_nodes[1].makeCodeParts(test)
      let rv = r[0].replaceSemicolon(@[(OTHER, "")])
      let ls = l[1].split("::")
      # TODO: 最悪
      # echo identTable[l[0][0].Code].arrayLength
      if identTable[l[0][0].Code].arrayLength <= rv[0].Code.parseInt() or rv[0].Code.parseInt() < 0:
        echoErrorMessage(10, test)
      if r[1] == INT and l[0][0].Type == IDENT and ls[0] == ARRAY:
        code.add(l[0].replaceSemicolon(@[(OTHER, "")]))
        code.add((OTHER, "["))
        code.add(rv)
        code.add((OTHER, "]"))
        code.addSemicolon()
        codeType = ls[1..ls.len()-1].join("::")
      else:
        echoErrorMessage(8, test)
    else:
      echoErrorMessage(7, test)

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
          echoErrorMessage(11, test)
      else:
        echoErrorMessage(2, test)
      code.add(l[0].replaceSemicolon(@[(OTHER, "")]))
      lt = l[1]

      code.add((OTHER, "="))
      let r = node.child_nodes[1].makeCodeParts(test)
      code.add(r[0])
      identTable[lmc].contents = r[0]
      rt = r[1]
    else:
      echoErrorMessage(7, test)
    code.addSemicolon()
    if typeMatch(lt, rt)[0]:
      codeType = lt
    else:
      echoErrorMessage(9, test)

  # 前置
  # TODO 
  of nkCallExpression:
    let fn = node.child_nodes[0].makeCodeParts(test)
    code.add(fn[0])
    var argsCode: seq[codeParts]
    var argsType: seq[string]
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
    
    for arg in node.child_nodes[1].child_nodes:
      code.add((OTHER, "("))
      let a = arg.makeCodeParts(test)
      code.add(a[0].replaceSemicolon(@[(OTHER, "")]))
      argsCode.add(a[0])
      argsType.add(a[1])
      code.add((OTHER, ")"))
    code.addSemicolon()
    # TODO
    # let fm = identExistenceCheck(node.function.identValue)
    let fm = conversionCppFunction(node.child_nodes[0].token.Literal, argsType)
    if fm[0] == false:
      echoErrorMessage(2, test)
    else:
      # 特殊
      case fm[2]
      of "_k_join":
        let ats = argsCode.searchCodeParts("@ARRAYLENGTH")
        if ats.len() >= 2:
          # 最悪
          code.add(("@ARRAYLENGTH", $(ats[ats.len()-1].Code.parseInt() + ats[ats.len()-2].Code.parseInt())))
      
      codeType = fm[1]

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
      echoErrorMessage(12, test)

  # else式
  of nkElseExpression:
    var sr = node.child_nodes[0].makeCodeParts(test)
    code.add(sr[0].replaceSemicolon(@[(OTHER, "")]))
    codeType = sr[1]

  # for文
  # TODO
  of nkForStatement:
    let obp = blockPath
    code.add((OTHER, "for"))
    code.add((OTHER, "("))
    code.add(node.child_nodes[0].makeCodeParts(test)[0])
    code.add((OTHER, ")"))
    code.add((OTHER, "{"))
    var sr: (seq[codeParts], string)
    for i, statement in node.child_nodes[1].child_nodes:
      sr = statement.makeCodeParts(test)
      code.add(sr[0])
    code.add((OTHER, "}"))
    code.add((OTHER, "\n"))
    blockPath = obp
    codeType = sr[1]
  else:
    return (code, codeType)
  
  return (code, codeType)

proc makeCppCode*(node: Node, indent: int, test: bool): string =
  var codeParts = makeCodeParts(node, test)
  var outCode: seq[string]
  var newLine: string
  var braceCount: int = indent

  for i, part in codeParts[0]:
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