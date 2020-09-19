import ka2token, ka2node, ka2token
import strutils, tables

#------↓仮↓------

type codeParts = tuple
  Type: string
  Code: string

var
  identTable = initTable[string, string]()
  scopeTable: seq[seq[string]]
  mutTable: seq[string]
  count = 0

proc initTables*() =
  identTable = initTable[string, string]()
  scopeTable = @[@[""]]
  mutTable = @[""]
  count = 0

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

proc conversionCppFunction(fn: string): (string, string) =
  case fn
  of PLUS:
    return (INT & "|" & FLOAT & "=>" & INT & "|" & FLOAT, "k_add")
  of MINUS:
    return (INT & "|" & FLOAT & "=>" & INT & "|" & FLOAT, "k_sub")
  of ASTERISC:
    return (INT & "|" & FLOAT & "=>" & INT & "|" & FLOAT, "k_mul")
  of SLASH:
    return (INT & "|" & FLOAT & "=>" & INT & "|" & FLOAT, "k_div")
  of LT:
    return (INT & "|" & FLOAT & "|" & CHAR & "|" & STRING & "|" & BOOL & "=>" & BOOL, "k_lt")
  of GT:
    return (INT & "|" & FLOAT & "|" & CHAR & "|" & STRING & "|" & BOOL & "=>" & BOOL, "k_gt")
  of LE:
    return (INT & "|" & FLOAT & "|" & CHAR & "|" & STRING & "|" & BOOL & "=>" & BOOL, "k_le")
  of GE:
    return (INT & "|" & FLOAT & "|" & CHAR & "|" & STRING & "|" & BOOL & "=>" & BOOL, "k_ge")
  of EE:
    return (INT & "|" & FLOAT & "|" & CHAR & "|" & STRING & "|" & BOOL & "=>" & BOOL, "k_eq")
  of NE:
    return (INT & "|" & FLOAT & "|" & CHAR & "|" & STRING & "|" & BOOL & "=>" & BOOL, "k_ne")
  of "puts":
    return (INT & "|" & FLOAT & "|" & CHAR & "|" & STRING & "|" & BOOL & "=>" & NIL, "k_puts")
  else:
    return (NIL, "NULL")

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

proc addScopeTable(str: string) =
  if scopeTable.len()-1 == count:
    scopeTable[count].add(str)
  elif scopeTable.len()-1 < count:
    scopeTable.setLen(count)
    scopeTable.add(@[str])

proc typeMatch(type1: string, type2: string): (bool, string) =
  var
    typeList1: seq[seq[string]]
    typeList2: seq[seq[string]]
  for t1s in type1.split("->"):
    typeList1.add(@[t1s.split("|")])
  for t2s in type2.split("->"):
    typeList2.add(@[t2s.split("|")])
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

proc funcTypesMatch(funcType: string, argsType: seq[string]): (bool, string, string) =
  var fnTs = funcType.split("=>")
  let res = typeMatch(fnTs[0], argsType.join("->"))
  
  if fnTs.len() == 1 or res[0] == false:
    return (false, "", "")
  
  return (res[0], res[1], fnTs[1])

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
      for i, arv in node.arrayValue:
        let elem = arv.makeCodeParts()
        if i == 0:
          eltype = elem[1]
          code.add(elem[0])
        elif typeMatch(elem[1], eltype)[0]:
          code.add((COMMA, ","))
          code.add(elem[0])
        else:
          echo "エラー！！！(0.0.1)"
          quit()
      code.add((RBRACE, "}"))
      codeType = ARRAY & "->" & eltype
    else:
      code.add((LBRACE, "{"))
      code.add((RBRACE, "}"))
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
    var im = false
    if scopeTable.len() != 0:
      var indmax = 0
      if count > scopeTable.len()-1:
        indmax = scopeTable.len()-1
      else:
        indmax = count
      for s in scopeTable[0..indmax]:
        for ident in s:
          if ident == node.identValue:
            code.add((IDENT, node.identValue))
            codeType = identTable[ident]
            im = true
            break
        if im:
          break
    if im == false:
      let ic = node.identValue.conversionCppFunction()
      if ic[0] != NIL:
        code.add((IDENT, ic[1]))
        codeType = ic[0]
      else:
        code.add((IDENT, node.identValue))
        codeType = IDENT

  # 仮
  of nkMapFunction:
    code.add((FUNCTION, "k_map"))
    codeType = ARRAY & "->" & INT
  
  # let文
  of nkLetStatement:
    code.add((OTHER, "const"))
    let li = node.let_ident.makeCodeParts()
    let lv = node.let_value.makeCodeParts()
    # echo li[1] & "___" & lv[1]
    if typeMatch(li[1], lv[1])[0]:
      if scopeTable.len() != 0:
        for sc in scopeTable:
          for ident in sc:
            if ident == li[0][1][1]:
              echo "エラー！！！(8)"
              quit()
      code.add(li[0])
      code.add((OTHER, "="))
      code.add(lv[0])
      code.addSemicolon()
      identTable[li[0][1][1]] = li[1]
      addScopeTable(li[0][1][1])
      # 後で消す
      echo scopeTable
      #
    else:
      echo "エラー！！！(9)"
      quit()
  
  # mut文
  # TODO
  of nkMutStatement:
    let li = node.let_ident.makeCodeParts()
    let lv = node.let_value.makeCodeParts()
    if typeMatch(li[1], lv[1])[0]:
      if scopeTable.len() != 0:
        for sc in scopeTable:
          for ident in sc:
            if ident == li[0][1][1]:
              echo "エラー！！！(10)"
              quit()
      code.add(li[0])
      code.add((OTHER, "="))
      code.add(lv[0])
      code.addSemicolon()
      identTable[li[0][1][1]] = li[1]
      addScopeTable(li[0][1][1])
      mutTable.add(li[0][1][1])
      # 後で消す
      echo scopeTable
      #
    else:
      echo "エラー！！！(11)"
      quit()

  # def文
  of nkDefineStatement:
    code.add((AUTO, "auto"))
    let di = node.define_ident.makeCodeParts()
    echo scopeTable
    if scopeTable.len() != 0:
      for sc in scopeTable:
        for ident in sc:
          if ident == di[0][1][1]:
            echo "エラー！！！(12)"
            quit()
    code.add(di[0][1])
    code.add((EQUAL, "="))
    if node.define_args == @[]:
      identTable[di[0][1][1]] = NIL & "=>" & di[1]
    else:
      var argsType: seq[string]
      for parameter in node.define_args:
        argsType.add(parameter.token.Type.removeT())
      identTable[di[0][1][1]] = argsType.join("->") & "=>" & di[1]
    addScopeTable(di[0][1][1])
    let oc = count
    count += 1
    # 後で消す
    echo scopeTable
    #
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
        identTable[arg] = pr[1]
        addScopeTable(arg)
        # 後で消す
        echo scopeTable
        #
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
    count -= 1
    scopeTable.setLen(oc + 1)
    # 後で消す
    echo scopeTable
    #
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
    let oc = node.operator.conversionCppFunction()
    code.add((node.token.Type, oc[1]))
    var lt, rt: string
    if node.left != nil:
      let l = node.left.makeCodeParts()
      code.add((OTHER, "("))
      code.add(l[0])
      code.add((OTHER, ")"))
      lt = l[1]
    if node.right != nil:
      let r = node.right.makeCodeParts()
      code.add((OTHER, "("))
      code.add(r[0])
      code.add((OTHER, ")"))
      rt = r[1]
    let om = funcTypesMatch(oc[0], @[lt, rt])
    if lt == "" and rt == "":
      codeType = FUNCTION
    elif lt == "":
      codeType = FUNCTION
    elif rt == "":
      codeType = FUNCTION
    elif om[0]:
      codeType = om[2]
    else:
      echo "エラー！！！(16.0)"
      quit()
  
  # Generator
  of nkGenerator:
    # TODO: 型のチェック
    if node.left != nil:
      let l = node.left.makeCodeParts()
      code.add(l[0])
      count += 1
      identTable[l[0][1][1]] = l[1]
      addScopeTable(l[0][1][1])
      # 後で消す
      echo scopeTable
      #
      codeType = l[1]
    else:
      echo "エラー！！！(15.1)"
      quit()
    code.add((COLON, ":"))
    if node.right != nil:
      let r = node.right.makeCodeParts()
      code.add(r[0])
    else:
      echo "エラー！！！(15.2)"
      quit()

  # 代入式
  of nkAssignExpression:
    var lt, rt: string
    if node.left != nil:
      # 値を代入しようとしている変数のチェック
      let l = node.left.makeCodeParts()
      var lmc: string = l[0][l[0].len()-1].Code
      if lmc == ";":
        lmc = l[0][l[0].len()-2].Code
      if lmc notin mutTable:
        echo "エラー！！！(16.0.0.1)"
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
    var argsType: seq[string]
    if node.function.kind == nkMapFunction:
      code.add((OTHER, "("))
      for i, arg in node.args:
        if i != 0:
          code.add((OTHER, ","))
        let a = arg.makeCodeParts()[0]
        code.add(a.replaceSemicolon((OTHER, "")))
      code.add((OTHER, ")"))
      code.addSemicolon()
    else:
      for arg in node.args:
        code.add((OTHER, "("))
        let a = arg.makeCodeParts()
        code.add(a[0].replaceSemicolon((OTHER, "")))
        argsType.add(a[1])
        code.add((OTHER, ")"))
      code.addSemicolon()
    let fm = funcTypesMatch(fn[1], argsType)
    if fm[0] == false:
      echo "エラー！！！(16.2)"
      quit()
    codeType = fm[2]
  
  # if式
  # TODO
  of nkIfExpression:
    code.add((OTHER, "("))
    code.add(node.condition.makeCodeParts()[0])
    code.add((OTHER, "?"))
    var sr: (seq[codeParts], string)
    for i, statement in node.consequence.statements:
      if i == node.consequence.statements.len()-1:
        sr = statement.makeCodeParts()
        code.add(sr[0].replaceSemicolon((OTHER, "")))
      else:
        sr = statement.makeCodeParts()
        code.add(sr[0].replaceSemicolon((OTHER, ",")))
    let ar = node.alternative.makeCodeParts()
    if typeMatch(ar[1], sr[1])[0]:
      code.add((OTHER, ":"))
      code.add(ar[0])
      codeType = sr[1]
      code.add((OTHER, ")"))
      code.addSemicolon()
    else:
      echo "エラー！！！(17)"
      quit()

  # elif式
  of nkElifExpression:
    code.add((OTHER, "("))
    code.add(node.condition.makeCodeParts()[0])
    code.add((OTHER, "?"))
    var sr: (seq[codeParts], string)
    for i, statement in node.consequence.statements:
      if i == node.consequence.statements.len()-1:
        sr = statement.makeCodeParts()
        code.add(sr[0].replaceSemicolon((OTHER, "")))
      else:
        sr = statement.makeCodeParts()
        code.add(sr[0].replaceSemicolon((OTHER, ",")))
    let ar = node.alternative.makeCodeParts()
    if typeMatch(ar[1], sr[1])[0]:
      code.add((OTHER, ":"))
      code.add(ar[0])
      codeType = sr[1]
      code.add((OTHER, ")"))
    else:
      echo "エラー！！！(18)"
      quit()

  # else式
  of nkElseExpression:
    var sr: (seq[codeParts], string)
    for i, statement in node.consequence.statements:
      if i == node.consequence.statements.len()-1:
        sr = statement.makeCodeParts()
        code.add(sr[0].replaceSemicolon((OTHER, "")))
      else:
        sr = statement.makeCodeParts()
        code.add(sr[0].replaceSemicolon((OTHER, ",")))
    codeType = sr[1]
  
  # for文
  # TODO
  of nkForStatement:
    let oc = count
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
    count -= 1
    scopeTable.setLen(oc + 1)
    codeType = sr[1]
    # 後で消す
    echo scopeTable
    #
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
      outCode.add(ind & newLine & "\n")
      braceCount = braceCount + 1
      newLine = ""
    elif part.Type == OTHER and part.Code == "}":
      if newLine.split(" ").join("") != "":
        outCode.add(newLine)
      braceCount = braceCount - 1
      newLine = ""
      newLine.addIndent(braceCount)
      newLine.add(part.Code & " ")
    elif part.Type == OTHER and part.Code == "?":
      newLine.add(part.Code)
      var ind = ""
      ind.addIndent(braceCount)
      outCode.add(ind & newLine & "\n")
      braceCount = braceCount + 1
      newLine = ""
    elif part.Type == OTHER and part.Code == ":":
      var ind = ""
      ind.addIndent(braceCount)
      outCode.add(ind & newLine & "\n")
      newLine = ""
      newLine.add(part.Code & " ")
    elif part.Type == OTHER and part.Code == "\n":
      newLine.add(part.Code)
    elif part.Type == OTHER and part.Code == "":
      continue
    else:
      newLine.add(part.Code & " ")
    
  outCode.add(newLine)
  
  return outCode.join()