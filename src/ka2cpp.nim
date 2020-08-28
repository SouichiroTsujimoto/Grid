import ka2token, ka2node, ka2token
import strutils, tables

#------仮------
type codeParts = tuple
  Type: string
  Code: string

var identTable = initTable[string, string]()
var scopeTable: seq[seq[string]]
var count = 0
#--------------

proc conversionCppFunction(operator: string): (string, string) =
  case operator
  of PLUS:
    return (INT, "k_add")
  of MINUS:
    return (INT, "k_sub")
  of ASTERISC:
    return (INT, "k_mul")
  of SLASH:
    return (INT, "k_div")
  of LT:
    return (BOOL, "k_lt")
  of GT:
    return (BOOL, "k_gt")
  of LE:
    return (BOOL, "k_le")
  of GE:
    return (BOOL, "k_ge")
  of EQ:
    return (BOOL, "k_eq")
  of NE:
    return (BOOL, "k_ne")
  #------仮------
  of "puts":
    return (NIL, "k_puts")
  else:
    return (NIL, "nil")

proc addSemicolon*(parts: var seq[codeParts]) =
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
    scopeTable.add(@[str])

proc makeCodeParts(node: Node): (seq[codeParts], string) =
  var code: seq[codeParts]
  var codeType: string
  
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
  of nkNIl:
    code.add((NIL, "NULL"))
    codeType = NIL
  of nkIntType:
    if node.identValue != "":
      code.add((T_INT, "int"))
      code.add((INT, node.identValue))
      codeType = INT
    else:
      echo "エラー！！！"
      quit()
  of nkFloatType:
    if node.identValue != "":
      code.add((T_FLOAT, "float"))
      code.add((FLOAT, node.identValue))
      codeType = FLOAT
    else:
      echo "エラー！！！"
      quit()
  of nkCharType:
    if node.identValue != "":
      code.add((T_CHAR, "char"))
      code.add((CHAR, node.identValue))
      codeType = CHAR
    else:
      echo "エラー！！！"
      quit()
  of nkStringType:
    if node.identValue != "":
      code.add((T_STRING, "std::string"))
      code.add((STRING, node.identValue))
      codeType = STRING
    else:
      echo "エラー！！！"
      quit()
  of nkBoolType:
    if node.identValue != "":
      code.add((T_BOOL, "bool"))
      code.add((BOOL, node.identValue))
      codeType = BOOL
    else:
      echo "エラー！！！"
      quit()
  of nkFunctionType:
    if node.identValue != "":
      code.add((T_FUNCTION, "auto"))
      code.add((FUNCTION, node.identValue))
      codeType = FUNCTION
    else:
      echo "エラー！！！"
      quit()
  of nkCppCode:
    if node.cppCodeValue != "":
      code.add((CPPCODE, node.cppCodeValue))
      code.addSemicolon()
      codeType = CPPCODE
    else:
      echo "エラー！！！"
      quit()
  
  # 名前
  of nkIdent:
    var im = false
    for s in scopeTable[0..count]:
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
      if ic[1] != "nil":
        code.add((IDENT, ic[1]))
        codeType = ic[0]
      else:
        code.add((IDENT, node.identValue))
        codeType = IDENT
  
  # let文
  of nkLetStatement:
    code.add((OTHER, "const"))
    let li = node.let_ident.makeCodeParts()
    let lv = node.let_value.makeCodeParts()
    if li[1] == lv[1]:
      for sc in scopeTable:
        for ident in sc:
          if ident == li[0][1][1]:
            echo "エラー！！！"
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
      echo "エラー！！！"
      quit()

  # def文
  of nkDefineStatement:
    code.add((AUTO, "auto"))
    let di = node.define_ident.makeCodeParts()
    for sc in scopeTable:
      for ident in sc:
        if ident == di[0][1][1]:
          echo "エラー！！！"
          quit()
    code.add(di[0][1])
    identTable[di[0][1][1]] = FUNCTION & "->" & di[1]
    addScopeTable(di[0][1][1])
    let oc = count
    count += 1
    # 後で消す
    echo scopeTable
    #
    code.add((ASSIGN, "="))
    var arg: string = ""
    if node.define_args == @[]:
      code.add((OTHER, "[]"))
      code.add((OTHER, "()"))
      code.add((OTHER, "{"))
      for statement in node.define_block.statements:
        if statement.kind == nkReturnStatement:
          let st = statement.makeCodeParts()
          if st[1] == di[1]:
            code.add(st[0])
          else:
            echo "エラー！！！"
            quit()
        else:
          code.add(statement.makeCodeParts()[0])
      code.add((OTHER, "}"))
      code.addSemicolon()
    else:
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
          if st[1] == di[1]:
            code.add(st[0])
          else:
            echo "エラー！！！"
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
      echo "エラー！！！"
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
    if lt == "" and rt == "":
      codeType = FUNCTION
    elif lt == "":
      codeType = FUNCTION
    elif rt == "":
      codeType = FUNCTION
    elif lt == rt:
      codeType = oc[0]
    else:
      echo "エラー！！！"
      quit()

  # 前置
  of nkCallExpression:
    code.add(node.function.makeCodeParts()[0])
    for arg in node.args:
      code.add((OTHER, "("))
      let a = arg.makeCodeParts()[0]
      code.add(a.replaceSemicolon((OTHER, "")))
      code.add((OTHER, ")"))
    code.addSemicolon()
  
  # if式
  of nkIfExpression:
    code.add((OTHER, "("))
    code.add(node.condition.makeCodeParts()[0])
    code.add((OTHER, "?"))
    for i, statement in node.consequence.statements:
      if i == node.consequence.statements.len()-1:
        code.add(statement.makeCodeParts()[0].replaceSemicolon((OTHER, "")))
      else:
        code.add(statement.makeCodeParts()[0].replaceSemicolon((OTHER, ",")))
    code.add((OTHER, ":"))
    code.add(node.alternative.makeCodeParts()[0])
    code.add((OTHER, ")"))
    code.addSemicolon()

  # elif式
  of nkElifExpression:
    code.add((OTHER, "("))
    code.add(node.condition.makeCodeParts()[0])
    code.add((OTHER, "?"))
    for i, statement in node.consequence.statements:
      if i == node.consequence.statements.len()-1:
        code.add(statement.makeCodeParts()[0].replaceSemicolon((OTHER, "")))
      else:
        code.add(statement.makeCodeParts()[0].replaceSemicolon((OTHER, ",")))
    code.add((OTHER, ":"))
    code.add(node.alternative.makeCodeParts()[0])
    code.add((OTHER, ")"))

  # else式
  of nkElseExpression:
    for i, statement in node.consequence.statements:
      if i == node.consequence.statements.len()-1:
        code.add(statement.makeCodeParts()[0].replaceSemicolon((OTHER, "")))
      else:
        code.add(statement.makeCodeParts()[0].replaceSemicolon((OTHER, ",")))
  else:
    return (code, codeType)
  
  return (code, codeType)

proc makeCppCode*(node: Node, indent: int): string =
  var codeParts = makeCodeParts(node)
  var outCode: seq[string]
  var newLine: string
  var braceCount: int = indent
  newLine.addIndent(braceCount)

  for i, part in codeParts[0]:
    # echo $i & "回目 : " & part
    # echo braceCount
    if part.Type != STRING and part.Code == "{":
      braceCount = braceCount + 1
      newLine.add(part.Code)
      outCode.add(newLine & "\n")
      newLine = ""
      newLine.addIndent(braceCount)
    elif part.Type != STRING and part.Code == "}":
      braceCount = braceCount - 1
      newLine = ""
      newLine.addIndent(braceCount)
      newLine.add(part.Code & " ")
    elif part.Type != STRING and part.Code == ";":
      newLine.add(part.Code)
      outCode.add(newLine & "\n")
      newLine = ""
      newLine.addIndent(braceCount)
    elif part.Type != STRING and part.Code == "?":
      braceCount = braceCount + 1
      newLine.add(part.Code)
      outCode.add(newLine & "\n")
      newLine = ""
      newLine.addIndent(braceCount)
    elif part.Type != STRING and part.Code == ":":
      braceCount = braceCount - 1
      newLine.add(part.Code)
      outCode.add(newLine & "\n")
      newLine = ""
      newLine.addIndent(braceCount)
    else:
      newLine.add(part.Code & " ")
    
  outCode.add(newLine)
  
  return outCode.join()