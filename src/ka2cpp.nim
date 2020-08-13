import ka2token, ka2node

proc conversionCppType(kind: NodeKind): string =
  case kind
  of nkIntLiteral:
    return "int"
  of nkFloatLiteral:
    return "float"
  of nkCharLiteral:
    return "char"
  of nkStringLiteral:
    return "std::string"
  else:
    return "auto"

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
  of EQ:
    return "k_eq"

proc makeCppCode*(node: Node): string =
  var str: string = ""
  case node.kind
  # リテラル
  of nkIntLiteral:
    str.add($node.intValue)
  of nkFloatLiteral:
    str.add($node.floatValue)
  of nkBoolLiteral:
    str.add($node.boolValue)
  of nkCharLiteral:
    str.add("\'" & node.charValue & "\'")
  of nkStringLiteral:
    str.add("\"" & node.stringValue & "\"")
  
  # 名前
  of nkIdent:
    str.add($node.identValue)
  
  # 文
  of nkLetStatement:
    str.add(node.let_value.kind.conversionCppType())
    str.add(" " & node.let_name.makeCppCode())
    str.add(" =")
    str.add(" " & node.let_value.makeCppCode())
    str.add(";")
  of nkDefineStatement:
    str.add(node.return_statement.return_expression.kind.conversionCppType())
    str.add(" " & node.define_name.makeCppCode())
    str.add("(")
    for i, arg in node.define_args:
      str.add("auto ")
      str.add(arg.makeCppCode())
      if i != node.define_args.len()-1:
        str.add(", ")
      else:
        str.add(")")
    str.add(" =")
    str.add(" {\n")
    for statement in node.define_block.statements:
      str.add(statement.makeCppCode())
    str.add(node.return_statement.makeCppCode())
    str.add("\n}")
  of nkReturnStatement:
    str.add("")
    str.add(node.token.Literal)
    str.add("(" & node.return_expression.makeCppCode() & ")")
    str.add(";")
  
  # 中置
  of nkInfixExpression:
    str.add(node.operator.conversionCppFunction())
    if node.left != nil:
      str.add("(" & node.left.makeCppCode() & ")")
    if node.right != nil:
      str.add("(" & node.right.makeCppCode() & ")")
  
  # 前置
  of nkCallExpression:
    str.add(node.function.makeCppCode())
    for arg in node.args:
      str.add("(" & arg.makeCppCode() & ")")
    str.add(";")
  
  # if文
  of nkIfExpression:
    str.add("if")
    str.add("(" & node.condition.makeCppCode() & ")")
    str.add("{\n")
    for statement in node.consequence.statements:
      str.add(statement.makeCppCode())
    str.add("\n}")
  
  # if-else文
  of nkIfAndElseExpression:
    str.add("if")
    str.add("(" & node.condition.makeCppCode() & ")")
    str.add("{\n")
    for statement in node.consequence.statements:
      str.add(statement.makeCppCode())
    str.add("\n}")
    str.add("else")
    str.add("{\n")
    for statement in node.alternative.statements:
      str.add(statement.makeCppCode())
    str.add("\n}")
  else:
    return str
  
  return str