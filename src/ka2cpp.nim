import ka2token, ka2node, ka2token
import strutils

#------仮------
type codeParts = tuple
  Type: string
  Code: string
#--------------

proc conversionCppFunction(operator: string): string =
  case operator
  of PLUS:
    return "k_add"
  of MINUS:
    return "k_sub"
  of ASTERISC:
    return "k_mul"
  of SLASH:
    return "k_div"
  of LT:
    return "k_lt"
  of GT:
    return "k_gt"
  of LE:
    return "k_le"
  of GE:
    return "k_ge"
  of EQ:
    return "k_eq"
  of NE:
    return "k_ne"
  #------仮------
  of "puts":
    return "k_puts"
  else:
    return "nil"

proc addSemicolon*(parts: var seq[codeParts]) =
  let tail = parts[parts.len()-1]
  if tail.Type != SEMICOLON:
    parts.add((SEMICOLON, ";"))

proc replaceSemicolon(parts: seq[codeParts], obj: codeParts): seq[codeParts] =
  var tail = parts[0]
  if tail.Type == SEMICOLON:
    tail = obj
    return parts[0..parts.len()-1] & tail
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
    if node.identValue.conversionCppFunction() != "nil":
      code.add((node.token.Type, node.identValue.conversionCppFunction()))
    else:
      code.add((node.token.Type, node.identValue))
  
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
    code.add((IDENT, di[0][1][1]))
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
    code.add((node.token.Type, node.operator.conversionCppFunction()))
    if node.left != nil:
      code.add((OTHER, "("))
      code.add(node.left.makeCodeParts()[0])
      code.add((OTHER, ")"))
    if node.right != nil:
      code.add((OTHER, "("))
      code.add(node.right.makeCodeParts()[0])
      code.add((OTHER, ")"))
  
  # 前置
  of nkCallExpression:
    code.add(node.function.makeCodeParts()[0])
    for arg in node.args:
      code.add((OTHER, "("))
      code.add(arg.makeCodeParts()[0])
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