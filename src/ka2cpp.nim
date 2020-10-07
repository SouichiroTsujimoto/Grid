import ka2token, ka2node, ka2token
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

proc deletePathTail(): string =
  let bps = blockPath.split("-")

  return bps[0..bps.len()-2].join("-")

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

  for t1s in type1.split("->"):
    typeList1.add(@[t1s.split("|")])
  for t2s in type2.split("->"):
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
        typeFlow.add("->")
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
  var fnTs = funcType.funcTypeSplit("=>")
  let res = typeMatch(fnTs[1], argsType)
  
  if fnTs[0] == false or res[0] == false or argsType == "":
    return (false, "", fnTs[1])
  
  return (res[0], res[1], fnTs[2])

proc conversionCppType(Type: string): (string, string) =
  let ts = Type.split("->")
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
      return (T_ARRAY, "std::vector<" & ts[1..ts.len()-1].join("->").conversionCppType()[1] & ">")
    of T_FUNCTION:
      return (T_FUNCTION, "auto")
    else:
      return (NIL, "NULL")

proc conversionCppFunction(fn: string, argsType: seq[string]): (bool, string, string) =
  let anything_t = INT & "|" & FLOAT & "|" & CHAR & "|" & STRING & "|" & BOOL
  let number_t = INT & "|" & FLOAT
  var argsTypeC = argsType
  # for _ in [argsTypeC.len()-1..2]:
  #   argsTypeC.add("")
  case fn
  of PLUS:
    let fmr1 = funcTypesMatch(number_t & "=>" & number_t & "=>" & number_t, argsTypeC[0])
    if fmr1[0]:
      if argsTypeC.len()-1 != 0:
        let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
        return (fmr2[0], fmr2[1], "_k_add")
      else:
        return (true, number_t & "=>" & number_t, "_k_add")
    else:
      return (true, number_t & "=>" & number_t & "=>" & number_t, "_k_add")
  of MINUS:
    let fmr1 = funcTypesMatch(number_t & "=>" & number_t & "=>" & number_t, argsTypeC[0])
    if fmr1[0]:
      if argsTypeC.len()-1 != 0:
        let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
        return (fmr2[0], fmr2[1], "_k_sub")
      else:
        return (true, number_t & "=>" & number_t, "_k_sub")
    else:
      return (true, number_t & "=>" & number_t & "=>" & number_t, "_k_sub")
  of ASTERISC:
    let fmr1 = funcTypesMatch(number_t & "=>" & number_t & "=>" & number_t, argsTypeC[0])
    if fmr1[0]:
      if argsTypeC.len()-1 != 0:
        let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
        return (fmr2[0], fmr2[1], "_k_mul")
      else:
        return (true, number_t & "=>" & number_t, "_k_mul")
    else:
      return (true, number_t & "=>" & number_t & "=>" & number_t, "_k_mul")
  of SLASH:
    let fmr1 = funcTypesMatch(number_t & "=>" & number_t & "=>" & number_t, argsTypeC[0])
    if fmr1[0]:
      if argsTypeC.len()-1 != 0:
        let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
        return (fmr2[0], fmr2[1], "_k_div")
      else:
        return (true, number_t & "=>" & number_t, "_k_div")
    else:
      return (true, number_t & "=>" & number_t & "=>" & number_t, "_k_div")
  of LT:
    let fmr1 = funcTypesMatch(anything_t & "=>" & anything_t & "=>" & BOOL, argsTypeC[0])
    if fmr1[0]:
      if argsTypeC.len()-1 != 0:
        let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
        return (fmr2[0], BOOL, "_k_lt")
      else:
        return (true, anything_t & "=>" & BOOL, "_k_lt")
    else:
      return (true, anything_t & "=>" & anything_t & "=>" & BOOL, "_k_lt")
  of GT:
    let fmr1 = funcTypesMatch(anything_t & "=>" & anything_t & "=>" & BOOL, argsTypeC[0])
    if fmr1[0]:
      if argsTypeC.len()-1 != 0:
        let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
        return (fmr2[0], BOOL, "_k_gt")
      else:
        return (true, anything_t & "=>" & BOOL, "_k_gt")
    else:
      return (true, anything_t & "=>" & anything_t & "=>" & BOOL, "_k_gt")
  of LE:
    let fmr1 = funcTypesMatch(anything_t & "=>" & anything_t & "=>" & BOOL, argsTypeC[0])
    if fmr1[0]:
      if argsTypeC.len()-1 != 0:
        let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
        return (fmr2[0], BOOL, "_k_le")
      else:
        return (true, anything_t & "=>" & BOOL, "_k_le")
    else:
      return (true, anything_t & "=>" & anything_t & "=>" & BOOL, "_k_le")
  of GE:
    let fmr1 = funcTypesMatch(anything_t & "=>" & anything_t & "=>" & BOOL, argsTypeC[0])
    if fmr1[0]:
      if argsTypeC.len()-1 != 0:
        let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
        return (fmr2[0], BOOL, "_k_ge")
      else:
        return (true, anything_t & "=>" & BOOL, "_k_ge")
    else:
      return (true, anything_t & "=>" & anything_t & "=>" & BOOL, "_k_ge")
  of EE:
    let fmr1 = funcTypesMatch(anything_t & "=>" & anything_t & "=>" & BOOL, argsTypeC[0])
    if fmr1[0]:
      if argsTypeC.len()-1 != 0:
        let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
        return (fmr2[0], BOOL, "_k_ee")
      else:
        return (true, anything_t & "=>" & BOOL, "_k_ee")
    else:
      return (true, anything_t & "=>" & anything_t & "=>" & BOOL, "_k_ee")
  of NE:
    let fmr1 = funcTypesMatch(anything_t & "=>" & anything_t & "=>" & BOOL, argsTypeC[0])
    if fmr1[0]:
      if argsTypeC.len()-1 != 0:
        let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
        return (fmr2[0], BOOL, "_k_ne")
      else:
        return (true, anything_t & "=>" & BOOL, "_k_ne")
    else:
      return (true, anything_t & "=>" & anything_t & "=>" & BOOL, "_k_ne")
  of "puts":
    let fmr1 = funcTypesMatch(anything_t & "=>" & NIL, argsTypeC[0])
    if fmr1[0]:
      return (fmr1[0], NIL, "_k_puts")
    else:
      return (true, anything_t & "=>" & NIL, "_k_puts")
  of "add":
    let fmr1 = funcTypesMatch(ARRAY & "->" & anything_t & "=>" & anything_t & "=>" & NIL, argsTypeC[0])
    if fmr1[0]:
      if argsTypeC.len()-1 != 0:
        let fmr2 = funcTypesMatch(fmr1[2], argsTypeC[1])
        if fmr2[0] and argsTypeC[0] == ARRAY & "->" & argsTypeC[1]:
          return (fmr2[0], fmr2[2], "_k_push_back")
      else:
        return (true, anything_t & "=>" & NIL, "_k_push_back")
    else:
      return (true, ARRAY & "->" & anything_t & "=>" & anything_t & "=>" & NIL, "_k_push_back")
  of "len":
    let fmr1 = funcTypesMatch(ARRAY & "->" & anything_t & "=>" & INT, argsTypeC[0])
    if fmr1[0]:
      return (fmr1[0], INT, "_k_len")
    else:
      return (true, ARRAY & "->" & anything_t & "=>" & INT, "_k_len")
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

proc replaceSemicolon(parts: seq[codeParts], obj: codeParts): seq[codeParts] =
  let tail = parts[parts.len()-1]
  if tail.Type == SEMICOLON:
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

proc makeCodeParts(node: Node): (seq[codeParts], string) =
  var
    code: seq[codeParts]
    codeType: string
  
  case node.kind
  # リテラル
  of nkIntLiteral:
    code.add((INT, $node.intValue))
    codeType = INT
  of nkFloatLiteral:
    code.add((FLOAT, $node.floatValue))
    codeType = FLOAT
    codeType = FLOAT
  of nkBoolLiteral:
    code.add((BOOL, $node.boolValue))
    codeType = BOOL
  of nkCharLiteral:
    code.add((CHAR, "\'" & $node.charValue & "\'"))
    codeType = CHAR
  of nkStringLiteral:
    code.add((STRING, "\"" & node.stringValue & "\""))
    codeType = STRING
  of nkCppCode:
    if node.cppCodeValue != "":
      code.add((CPPCODE, node.cppCodeValue))
      code.addSemicolon()
      codeType = CPPCODE
    else:
      echo "エラー！！！(0)"
      quit()
  of nkArrayLiteral:
    if node.arrayValue != @[]:
      code.add((LBRACE, "{"))
      var eltype: string
      var loopCount = 0
      for arv in node.arrayValue:
        let elem = arv.makeCodeParts()
        if loopCount == 0:
          eltype = elem[1]
          code.add(elem[0])
        elif typeMatch(elem[1], eltype)[0]:
          code.add((COMMA, ","))
          code.add(elem[0])
        else:
          echo "エラー！！！(0.0.1)"
          quit()
        loopCount += 1
      code.add((RBRACE, "}"))
      code.add(($loopCount, ""))
      codeType = ARRAY & "->" & eltype
    else:
      code.add((LBRACE, "{"))
      code.add((RBRACE, "}"))
      code.add(("0", ""))
      codeType = ARRAY
  of nkNIl:
    code.add((NIL, "NULL"))
    codeType = NIL
  of nkIntType:
    if node.identValue != "":
      code.add(node.typeValue.conversionCppType())
      code.add((INT, node.identValue))
      codeType = INT
    else:
      echo "エラー！！！(1)"
      quit()
  of nkFloatType:
    if node.identValue != "":
      code.add(node.typeValue.conversionCppType())
      code.add((FLOAT, node.identValue))
      codeType = FLOAT
    else:
      echo "エラー！！！(2)"
      quit()
  of nkCharType:
    if node.identValue != "":
      code.add(node.typeValue.conversionCppType())
      code.add((CHAR, node.identValue))
      codeType = CHAR
    else:
      echo "エラー！！！(3)"
      quit()
  of nkStringType:
    if node.identValue != "":
      code.add(node.typeValue.conversionCppType())
      code.add((STRING, node.identValue))
      codeType = STRING
    else:
      echo "エラー！！！(4)"
      quit()
  of nkBoolType:
    if node.identValue != "":
      code.add(node.typeValue.conversionCppType())
      code.add((BOOL, node.identValue))
      codeType = BOOL
    else:
      echo "エラー！！！(5)"
      quit()
  of nkArrayType:
    if node.identValue != "":
      code.add(node.typeValue.conversionCppType())
      code.add((node.typeValue, node.identValue))
      let types = node.typeValue.split("->")
      for i, tv in types:
        if i != 0:
          codeType.add("->")
        codeType.add(tv[2..tv.len()-1])
    else:
      echo "エラー！！！(5.1)"
      quit()
  of nkFunctionType:
    if node.identValue != "":
      code.add((T_FUNCTION, "auto"))
      code.add((FUNCTION, node.identValue))
      codeType = FUNCTION
    else:
      echo "エラー！！！(6)"
      quit()

  # 名前
  of nkIdent:
    if identExistenceCheck(node.identValue):
      code.add((IDENT, node.identValue))
      codeType = identTable[node.identValue].Type
    else:
      let ic = node.identValue.conversionCppFunction(@[""])
      if ic[0]:
        code.add((ic[1], ic[2]))
        codeType = ic[1]
      else:
        echo "エラー！！！(7)"
        quit()

  # 仮
  of nkMapFunction:
    code.add((IDENT, "_k_map"))
    codeType = IDENT
  
  # let文
  of nkLetStatement:
    code.add((OTHER, "const"))
    let li = node.let_ident.makeCodeParts()
    let lv = node.let_value.makeCodeParts()
    # echo li[1] & "___" & lv[1]
    if li[1] == lv[1]:
      if identExistenceCheck(li[0][1][1]):
        echo "エラー！！！(8)"
        quit()
      code.add(li[0])
      code.add((OTHER, "="))
      code.add(lv[0])
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
        identTable[li[0][1][1]].arrayLength = lv[0][lv[0].len()-1].Type.parseInt()
    else:
      echo "エラー！！！(9)"
      quit()
  
  # mut文
  of nkMutStatement:
    let li = node.let_ident.makeCodeParts()
    let lv = node.let_value.makeCodeParts()
    if li[1] == lv[1]:
      if identExistenceCheck(li[0][1][1]):
        echo "エラー！！！(10)"
        quit()
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
        identTable[li[0][1][1]].arrayLength = lv[0][lv[0].len()-1].Type.parseInt()
    else:
      echo "エラー！！！(11)"
      quit()

  # def文
  of nkDefineStatement:
    code.add((AUTO, "auto"))
    let di = node.define_ident.makeCodeParts()
    if identExistenceCheck(di[0][1][1]):
      echo "エラー！！！(12)"
      quit()
    code.add(di[0][1])
    code.add((EQUAL, "="))
    if node.define_args == @[]:
      identTable[di[0][1][1]] = IdentInfo(
        Type: NIL & "=>" & di[1],
        path: blockPath,
        mutable: false,
      )
    else:
      var argsType: seq[string]
      for parameter in node.define_args:
        argsType.add(parameter.token.Type.removeT())
      identTable[di[0][1][1]] = IdentInfo(
        Type: argsType.join("->") & "=>" & di[1],
        path: blockPath,
        mutable: false,
      )
    let obp = blockPath
    blockPath.add("-0")
    if node.define_args == @[]:
      code.add((OTHER, "[]"))
      code.add((OTHER, "()"))
      code.add((OTHER, "{"))
      for statement in node.define_block.statements:
        if statement.kind == nkReturnStatement:
          let st = statement.makeCodeParts()
          if typeMatch(st[1], di[1])[0]:
            code.add(st[0])
          else:
            echo "エラー！！！(13)"
            quit()
        else:
          code.add(statement.makeCodeParts()[0])
      code.add((OTHER, "}"))
      code.addSemicolon()
    else:
      var arg: string = ""
      for i, parameter in node.define_args:
        let pr = parameter.makeCodeParts()
        code.add((OTHER, "[" & arg & "]"))
        code.add((OTHER, "("))
        code.add(pr[0])
        code.add((OTHER, ")"))
        arg = parameter.identValue
        blockPath = nextPath()
        identTable[arg] = IdentInfo(
          Type: pr[1],
          path: blockPath,
        )
        code.add((OTHER, "{"))
        if i != node.define_args.len()-1:
          code.add((RETURN, "return"))
      for statement in node.define_block.statements:
        if statement.kind == nkReturnStatement:
          let st = statement.makeCodeParts()
          if typeMatch(st[1], di[1])[0]:
            code.add(st[0])
          else:
            echo "エラー！！！(14)"
            quit()
        else:
          code.add(statement.makeCodeParts()[0])
      for _ in node.define_args:
        code.add((OTHER, "}"))
        code.addSemicolon()
    blockPath = obp
    codeType = DEFINE

  # return文
  of nkReturnStatement:
    if node.return_expression != nil:
      code.add((OTHER, "return"))
      code.add((OTHER, "("))
      let r = node.return_expression.makeCodeParts()
      code.add(r[0].replaceSemicolon((OTHER, "")))
      code.add((OTHER, ")"))
      code.addSemicolon()
      codeType = r[1]
    else:
      echo "エラー！！！(15)"
      quit()
  
  # 中置
  of nkInfixExpression:
    var 
      l: (seq[codeParts], string)
      r: (seq[codeParts], string)
    if node.left != nil:
      l = node.left.makeCodeParts()
    if node.right != nil:
      r = node.right.makeCodeParts()
    if l[1] == "" and r[1] == "":
      let oc = node.operator.conversionCppFunction(@[""])
      code.add((node.token.Type, oc[2]))
      codeType = oc[1]
    elif l[1] == "":
      let oc = node.operator.conversionCppFunction(@[r[1]])
      code.add((node.token.Type, oc[2]))
      code.add((OTHER, "("))
      code.add(r[0].replaceSemicolon((OTHER, "")))
      code.add((OTHER, ")"))
      code.addSemicolon()
      codeType = oc[1]
    elif r[1] == "":
      let oc = node.operator.conversionCppFunction(@[l[1]])
      code.add((node.token.Type, oc[2]))
      code.add((OTHER, "("))
      code.add(l[0].replaceSemicolon((OTHER, "")))
      code.add((OTHER, ")"))
      code.addSemicolon()
      codeType = oc[1]
    elif typeMatch(l[1], r[1])[0]:
      let oc = node.operator.conversionCppFunction(@[l[1], r[1]])
      code.add((node.token.Type, oc[2]))
      if oc[0] == false:
        echo "エラー！！！(15.1)"
        quit()
      code.add((OTHER, "("))
      code.add(l[0].replaceSemicolon((OTHER, "")))
      code.add((OTHER, ")"))
      code.add((OTHER, "("))
      code.add(r[0].replaceSemicolon((OTHER, "")))
      code.add((OTHER, ")"))
      code.addSemicolon()
      codeType = oc[1]
    else:
      echo "エラー！！！(15.1.1)"
      quit()
  
  # Generator
  of nkGenerator:
    # TODO: 型のチェック
    var lt: string
    if node.left != nil:
      let l = node.left.makeCodeParts()
      code.add(l[0])
      lt = l[1]
      blockPath.add("-0")
      if identExistenceCheck(l[0][1][1]):
        echo "エラー！！！(15.1.1.1)"
        quit()
      identTable[l[0][1][1]] = IdentInfo(
        Type: lt,
        path: blockPath,
      )
      codeType = l[1]
    else:
      echo "エラー！！！(15.1.2)"
      quit()
    code.add((COLON, ":"))
    if node.right != nil:
      let r = node.right.makeCodeParts()
      if lt == r[1].split("ARRAY->")[1]:
        code.add(r[0])
      else:
        echo "エラー！！！(15.1.3)"
        quit()
    else:
      echo "エラー！！！(15.2)"
      quit()

  # パイプライン演算子
  of nkPipeExpression:
    node.right.args = node.left & node.right.args
    let r = node.right.makeCodeParts()
    code.add(r[0])
    codeType = r[1]
    
  # 配列の要素へのアクセス
  of nkAccessElement:
    if node.left != nil and node.right != nil:
      let l = node.left.makeCodeParts()
      let r = node.right.makeCodeParts()
      let rv = r[0].replaceSemicolon((OTHER, ""))
      let ls = l[1].split("->")
      # TODO: 最悪
      if identTable[l[0][0].Code].arrayLength <= rv[0].Code.parseInt() or rv[0].Code.parseInt() < 0:
        echo "エラー！！！(15.3.1)"
        quit()
      if r[1] == INT and l[0][0].Type == IDENT and ls[0] == ARRAY:
        code.add(l[0].replaceSemicolon((OTHER, "")))
        code.add((OTHER, "["))
        code.add(rv)
        code.add((OTHER, "]"))
        code.addSemicolon()
        codeType = ls[1..ls.len()-1].join("->")
      else:
        echo "エラー！！！(15.3.2)"
        quit()
    else:
      echo "エラー！！！(15.4)"
      quit()

  # 代入式
  of nkAssignExpression:
    var lt, rt: string
    var lmc: string
    if node.left != nil:
      # 値を代入しようとしている変数のチェック
      let l = node.left.makeCodeParts()
      lmc = l[0][l[0].len()-1].Code
      if lmc == ";":
        lmc = l[0][l[0].len()-2].Code
      if identExistenceCheck(lmc):
        if identTable[lmc].mutable == false:
          echo "エラー！！！(16.0.0.1)"
          quit()
      else:
        echo "エラー！！！(16.0.0.2)"
        quit()
      code.add(l[0].replaceSemicolon((OTHER, "")))
      lt = l[1]
    else:
      echo "エラー！！！(16.0.1)"
      quit()
    code.add((OTHER, "="))
    if node.right != nil:
      let r = node.right.makeCodeParts()
      code.add(r[0])
      identTable[lmc].contents = r[0]
      rt = r[1]
    else:
      echo "エラー！！！(16.0.2)"
      quit()
    code.addSemicolon()
    if typeMatch(lt, rt)[0]:
      codeType = lt
    else:
      echo "エラー！！！(16.1)"
      quit()

  # 前置
  # TODO 
  of nkCallExpression:
    let fn = node.function.makeCodeParts()
    code.add(fn[0])
    var argsCode: seq[codeParts]
    var argsType: seq[string]
    # 後でいろいろ変更
    if node.function.kind == nkMapFunction:
      code.add((OTHER, "("))
      var at: string
      for i, arg in node.args:
        let a = arg.makeCodeParts()
        if i != 0:
          code.add((OTHER, ","))
          at = a[1]
        code.add(a[0].replaceSemicolon((OTHER, "")))
      code.add((OTHER, ")"))
      code.addSemicolon()
      codeType = ARRAY & "->" & at.funcTypeSplit("=>")[2]
      echo codeType
    else:
      for arg in node.args:
        code.add((OTHER, "("))
        let a = arg.makeCodeParts()
        code.add(a[0].replaceSemicolon((OTHER, "")))
        argsCode.add(a[0])
        argsType.add(a[1])
        code.add((OTHER, ")"))
      code.addSemicolon()
      let fm = conversionCppFunction(node.function.identValue, argsType)
      if fm[0] == false:
        echo "エラー！！！(16.2)"
        quit()
      case fm[2]
      of "_k_push_back":
        identTable[argsCode[0].Code].arrayLength += 1
      codeType = fm[1]
  
  # if文
  of nkIfStatement:
    code.add((OTHER, "if"))
    code.add((OTHER, "("))
    code.add(node.condition.makeCodeParts()[0].replaceSemicolon((OTHER, "")))
    code.add((OTHER, ")"))
    code.add((OTHER, "{"))
    var sr: (seq[codeParts], string)
    for i, statement in node.consequence.statements:
      if i == node.consequence.statements.len()-1:
        sr = statement.makeCodeParts()
        code.add(sr[0])
      else:
        sr = statement.makeCodeParts()
        code.add(sr[0])
    code.add((OTHER, "}"))
    let ar = node.alternative.makeCodeParts()
    code.add(ar[0])
    codeType = sr[1]

  # elif文
  of nkElifStatement:
    code.add((OTHER, "else if"))
    code.add((OTHER, "("))
    code.add(node.condition.makeCodeParts()[0].replaceSemicolon((OTHER, "")))
    code.add((OTHER, ")"))
    code.add((OTHER, "{"))
    var sr: (seq[codeParts], string)
    for i, statement in node.consequence.statements:
      if i == node.consequence.statements.len()-1:
        sr = statement.makeCodeParts()
        code.add(sr[0])
      else:
        sr = statement.makeCodeParts()
        code.add(sr[0])
    code.add((OTHER, "}"))
    let ar = node.alternative.makeCodeParts()
    code.add(ar[0])
    codeType = sr[1]

  # else文
  of nkElseStatement:
    code.add((OTHER, "else"))
    code.add((OTHER, "{"))
    var sr: (seq[codeParts], string)
    for i, statement in node.consequence.statements:
      if i == node.consequence.statements.len()-1:
        sr = statement.makeCodeParts()
        code.add(sr[0])
      else:
        sr = statement.makeCodeParts()
        code.add(sr[0])
    code.add((OTHER, "}"))
    codeType = sr[1]
  
  # if式
  of nkIfExpression:
    code.add((OTHER, "("))
    code.add(node.condition.makeCodeParts()[0].replaceSemicolon((OTHER, "")))
    code.add((OTHER, "?"))
    var sr = node.consequence_expression.makeCodeParts()
    code.add(sr[0].replaceSemicolon((OTHER, "")))
    let ar = node.alternative.makeCodeParts()
    if typeMatch(ar[1], sr[1])[0]:
      code.add((OTHER, ":"))
      code.add(ar[0].replaceSemicolon((OTHER, "")))
      codeType = sr[1]
      code.add((OTHER, ")"))
      code.addSemicolon()
    else:
      echo "エラー！！！(17)"
      quit()

  # else式
  of nkElseExpression:
    var sr = node.consequence_expression.makeCodeParts()
    code.add(sr[0].replaceSemicolon((OTHER, "")))
    codeType = sr[1]

  # for文
  # TODO
  of nkForStatement:
    let obp = blockPath
    code.add((OTHER, "for"))
    code.add((OTHER, "("))
    code.add(node.generator.makeCodeParts()[0])
    code.add((OTHER, ")"))
    code.add((OTHER, "{"))
    var sr: (seq[codeParts], string)
    for i, statement in node.consequence.statements:
      sr = statement.makeCodeParts()
      code.add(sr[0])
    code.add((OTHER, "}"))
    code.add((OTHER, "\n"))
    blockPath = obp
    codeType = sr[1]
  else:
    return (code, codeType)
  
  return (code, codeType)

proc makeCppCode*(node: Node, indent: int): string =
  var codeParts = makeCodeParts(node)
  var outCode: seq[string]
  var newLine: string
  var braceCount: int = indent

  for i, part in codeParts[0]:
    # echo $i & "回目 : " & part
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
    elif part.Code == "":
      continue
    else:
      newLine.add(part.Code & " ")
    
  outCode.add(newLine)
  
  return outCode.join()