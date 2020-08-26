import ka2token, ka2node, ka2token
import strutils, tables

#------仮------
type codeParts = tuple
  Type: string
  Code: string

var identTable = initTable[string, string]()
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
      codeType = T_INT
    else:
      echo "エラー！！！"
  of nkFloatType:
    if node.identValue != "":
      code.add((T_FLOAT, "float"))
      code.add((FLOAT, node.identValue))
      codeType = T_FLOAT
    else:
      echo "エラー！！！"
  of nkCharType:
    if node.identValue != "":
      code.add((T_CHAR, "char"))
      code.add((CHAR, node.identValue))
      codeType = T_CHAR
    else:
      echo "エラー！！！"
  of nkStringType:
    if node.identValue != "":
      code.add((T_STRING, "std::string"))
      code.add((STRING, node.identValue))
      codeType = T_STRING
    else:
      echo "エラー！！！"
  of nkBoolType:
    if node.identValue != "":
      code.add((T_BOOL, "bool"))
      code.add((BOOL, node.identValue))
      codeType = T_BOOL
    else:
      echo "エラー！！！"
  of nkFunctionType:
    if node.identValue != "":
      code.add((T_FUNCTION, "auto"))
      code.add((FUNCTION, node.identValue))
      codeType = T_FUNCTION
    else:
      echo "エラー！！！"
  of nkCppCode:
    if node.cppCodeValue != "":
      code.add((CPPCODE, node.cppCodeValue))
      code.addSemicolon()
      codeType = CPPCODE
    else:
      echo "エラー！！！"
  
  # 名前
  of nkIdent:
    # 仮
    let ic = node.identValue.conversionCppFunction()
    if ic[1] != "nil":
      code.add((node.token.Type, ic[1]))
      codeType = ic[0]
    else:
      code.add((node.token.Type, node.identValue))
      codeType = IDENT
  
  # let文
  of nkLetStatement:
    code.add((OTHER, "const"))
    let li = node.let_ident.makeCodeParts()
    let lv = node.let_value.makeCodeParts()
    if li[1] == "T_" & lv[1]:
      code.add(li[0])
      code.add((OTHER, "="))
      code.add(lv[0])
      code.addSemicolon()
    else:
      echo "エラー！！！"

  # def文
  of nkDefineStatement:
    code.add((AUTO, "auto"))
    let di = node.define_ident.makeCodeParts()
    code.add(di[0][1])
    code.add((ASSIGN, "="))
    var arg: string = ""
    if node.define_args == @[]:
      code.add((OTHER, "[]"))
      code.add((OTHER, "()"))
      code.add((OTHER, "{"))
      for statement in node.define_block.statements:
        code.add(statement.makeCodeParts()[0])
      code.add((OTHER, "}"))
      code.addSemicolon()
    else:
      for i, parameter in node.define_args:
        code.add((OTHER, "[" & arg & "]"))
        code.add((OTHER, "("))
        code.add(parameter.makeCodeParts()[0])
        code.add((OTHER, ")"))
        arg = parameter.identValue
        code.add((OTHER, "{"))
        if i != node.define_args.len()-1:
          code.add((RETURN, "return"))
      for statement in node.define_block.statements:
        if statement.kind == nkReturnStatement:
          let st = statement.makeCodeParts()
          if "T_" & st[1] == di[1]:
            code.add(st[0])
          else:
            echo "エラー！！！"
        else:
          code.add(statement.makeCodeParts()[0])
      for _ in node.define_args:
        code.add((OTHER, "}"))
        code.addSemicolon()
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