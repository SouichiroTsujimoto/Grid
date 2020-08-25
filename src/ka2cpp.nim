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

proc makeCodeParts(node: Node): seq[codeParts] =
  var code: seq[codeParts]
  case node.kind
  # リテラル
  of nkIntLiteral:
    code.add((node.token.Type, $node.intValue))
  of nkFloatLiteral:
    code.add((node.token.Type, $node.floatValue))
  of nkBoolLiteral:
    code.add((node.token.Type, $node.boolValue))
  of nkCharLiteral:
    code.add((node.token.Type, "\'" & $node.charValue & "\'"))
  of nkStringLiteral:
    code.add((node.token.Type, "\"" & node.stringValue & "\""))
  of nkIntType:
    code.add((node.token.Type, "int"))
    if node.identValue != "":
      code.add((INT, node.identValue))
  of nkFloatType:
    code.add((node.token.Type, "float"))
    if node.identValue != "":
      code.add((FLOAT, node.identValue))
  of nkCharType:
    code.add((node.token.Type, "char"))
    if node.identValue != "":
      code.add((CHAR, node.identValue))
  of nkStringType:
    code.add((node.token.Type, "std::string"))
    if node.identValue != "":
      code.add((STRING, node.identValue))
  of nkBoolType:
    code.add((node.token.Type, "bool"))
    if node.identValue != "":
      code.add((BOOL, node.identValue))
  of nkCppCode:
    code.add((node.token.Type, node.cppCodeValue))
    code.addSemicolon()
  of nkNIl:
    code.add((node.token.Type, "NULL"))
  
  # 名前
  of nkIdent:
    # 仮
    if node.identValue.conversionCppFunction() != "nil":
      code.add((node.token.Type, node.identValue.conversionCppFunction()))
    else:
      code.add((node.token.Type, node.identValue))
  
  # let文
  of nkLetStatement:
    code.add(node.let_ident.makeCodeParts())
    code.add((ASSIGN, "="))
    code.add(node.let_value.makeCodeParts())
    code.addSemicolon()

  # def文
  of nkDefineStatement:
    code.add((AUTO, "auto"))
    code.add((IDENT, node.define_ident.identValue))
    code.add((ASSIGN, "="))
    var arg: string = ""
    if node.define_args == @[]:
      code.add((OTHER, "[]"))
      code.add((OTHER, "()"))
      code.add((OTHER, "{"))
      for statement in node.define_block.statements:
        code.add(statement.makeCodeParts())
      code.add((OTHER, "}"))
      code.addSemicolon()
    else:
      for i, parameter in node.define_args:
        code.add((OTHER, "[" & arg & "]"))
        code.add((OTHER, "("))
        code.add(parameter.makeCodeParts())
        code.add((OTHER, ")"))
        arg = parameter.identValue
        code.add((OTHER, "{"))
        if i != node.define_args.len()-1:
          code.add((RETURN, "return"))
      for statement in node.define_block.statements:
        code.add(statement.makeCodeParts())
      for _ in node.define_args:
        code.add((OTHER, "}"))
        code.addSemicolon()

  # return文
  of nkReturnStatement:
    code.add((OTHER, node.token.Literal))
    code.add((OTHER, "("))
    let r = node.return_expression.makeCodeParts().replaceSemicolon((OTHER, ""))
    code.add(r)
    code.add((OTHER, ")"))
    code.addSemicolon()
  
  # 中置
  of nkInfixExpression:
    code.add((node.token.Type, node.operator.conversionCppFunction()))
    if node.left != nil:
      code.add((OTHER, "("))
      code.add(node.left.makeCodeParts())
      code.add((OTHER, ")"))
    if node.right != nil:
      code.add((OTHER, "("))
      code.add(node.right.makeCodeParts())
      code.add((OTHER, ")"))
  
  # 前置
  of nkCallExpression:
    code.add(node.function.makeCodeParts())
    for arg in node.args:
      code.add((OTHER, "("))
      code.add(arg.makeCodeParts())
      code.add((OTHER, ")"))
    code.addSemicolon()
  
  # if式
  of nkIfExpression:
    code.add((OTHER, "("))
    code.add(node.condition.makeCodeParts())
    code.add((OTHER, "?"))
    for i, statement in node.consequence.statements:
      if i == node.consequence.statements.len()-1:
        code.add(statement.makeCodeParts().replaceSemicolon((OTHER, "")))
      else:
        code.add(statement.makeCodeParts().replaceSemicolon((OTHER, ",")))
    code.add((OTHER, ":"))
    code.add(node.alternative.makeCodeParts())
    code.add((OTHER, ")"))
    code.addSemicolon()

  # elif式
  of nkElifExpression:
    code.add((OTHER, "("))
    code.add(node.condition.makeCodeParts())
    code.add((OTHER, "?"))
    for i, statement in node.consequence.statements:
      if i == node.consequence.statements.len()-1:
        code.add(statement.makeCodeParts().replaceSemicolon((OTHER, "")))
      else:
        code.add(statement.makeCodeParts().replaceSemicolon((OTHER, ",")))
    code.add((OTHER, ":"))
    code.add(node.alternative.makeCodeParts())
    code.add((OTHER, ")"))

  # else式
  of nkElseExpression:
    for i, statement in node.consequence.statements:
      if i == node.consequence.statements.len()-1:
        code.add(statement.makeCodeParts().replaceSemicolon((OTHER, "")))
      else:
        code.add(statement.makeCodeParts().replaceSemicolon((OTHER, ",")))
  else:
    return code
  
  return code

proc makeCppCode*(node: Node, indent: int): string =
  var codeParts = makeCodeParts(node)
  var outCode: seq[string]
  var newLine: string
  var braceCount: int = indent
  newLine.addIndent(braceCount)

  for i, part in codeParts:
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