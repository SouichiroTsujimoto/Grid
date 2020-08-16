import ka2token, ka2node
import strutils

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
  else:
    return "k_hoge"

proc addSemicolon(code: var seq[string]) =
  if code[code.len()-1] != ";":
    code.add(";")

proc addIndent(code: var string, indent: int) =
  for i in 0..indent:
    code.add("  ")

proc makeCodeParts(node: Node): seq[string] =
  var code: seq[string]
  case node.kind
  # リテラル
  of nkIntLiteral:
    code.add($node.intValue)
  of nkFloatLiteral:
    code.add($node.floatValue)
  of nkBoolLiteral:
    code.add($node.boolValue)
  of nkCharLiteral:
    code.add("\'" & node.charValue & "\'")
  of nkStringLiteral:
    code.add("\"" & node.stringValue & "\"")
  of nkIntType:
    code.add("int")
    if node.identValue != "":
      code.add(node.identValue)
  of nkFloatType:
    code.add("double")
    if node.identValue != "":
      code.add(node.identValue)
  of nkCharType:
    code.add("char")
    if node.identValue != "":
      code.add(node.identValue)
  of nkStringType:
    code.add("std::string")
    if node.identValue != "":
      code.add(node.identValue)
  of nkNIl:
    code.add("NULL")
  
  # 名前
  of nkIdent:
    code.add(node.identValue)
  
  # let文
  of nkLetStatement:
    code.add(node.let_ident.makeCodeParts())
    code.add("=")
    code.add(node.let_value.makeCodeParts())
    code.addSemicolon()
  # def文
  of nkDefineStatement:
    code.add("auto")
    code.add(node.define_ident.identValue)
    code.add("=")
    var arg: string
    for i, parameter in node.define_args:
      code.add("[" & arg & "]")
      code.add("(" & parameter.makeCodeParts() & ")")
      arg = parameter.identValue
      code.add("{")
      if i != node.define_args.len()-1:
        code.add("return")
    for statement in node.define_block.statements:
      code.add(statement.makeCodeParts())
    for _ in node.define_args:
      code.add("}")
      code.add(";")
  # return文
  of nkReturnStatement:
    code.add(node.token.Literal)
    code.add("(" & node.return_expression.makeCodeParts() & ")")
    code.addSemicolon()
  
  # 中置
  of nkInfixExpression:
    code.add(node.operator.conversionCppFunction())
    if node.left != nil:
      code.add("(" & node.left.makeCodeParts() & ")")
    if node.right != nil:
      code.add("(" & node.right.makeCodeParts() & ")")
  
  # 前置
  of nkCallExpression:
    code.add(node.function.makeCodeParts())
    for arg in node.args:
      code.add("(" & arg.makeCodeParts() & ")")
    code.addSemicolon()
  
  # if文
  of nkIfExpression:
    code.add("if")
    code.add("(" & node.condition.makeCodeParts() & ")")
    code.add("{")
    for statement in node.consequence.statements:
      code.add(statement.makeCodeParts())
    code.add("}")
    if node.alternative != nil:
      code.add(node.alternative.makeCodeParts())

  # elif文
  of nkElifExpression:
    code.add("elif")
    code.add("(" & node.condition.makeCodeParts() & ")")
    code.add("{")
    for statement in node.consequence.statements:
      code.add(statement.makeCodeParts())
    code.add("}")
    if node.alternative != nil:
      code.add(node.alternative.makeCodeParts())

  # else文
  of nkElseExpression:
    code.add("else")
    code.add("{")
    for statement in node.consequence.statements:
      code.add(statement.makeCodeParts())
    code.add("}")
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
    if part == "{":
      braceCount = braceCount + 1
      newLine.add(part)
      outCode.add(newLine & "\n")
      newLine = ""
      newLine.addIndent(braceCount)
    elif part == "}":
      braceCount = braceCount - 1
      newLine = ""
      newLine.addIndent(braceCount)
      newLine.add(part & " ")
    elif part == ";":
      newLine.add(part)
      outCode.add(newLine & "\n")
      newLine = ""
      newLine.addIndent(braceCount)
    else:
      newLine.add(part & " ")
    
  outCode.add(newLine)
  
  return outCode.join()