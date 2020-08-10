import  ka2parser, ka2token, ka2node

proc echoNode(node: Node): string =
  var str: string = ""
  case node.kind
  of nkIntLiteral:
    str.add(node.token.Literal)
  of nkIdent:
    str.add(node.token.Literal)
  of nkLetStatement:
    str.add(node.token.Literal)
    str.add("(" & node.let_name.echoNode() & ")")
    str.add("(" & node.let_value.echoNode() & ")")
  of nkDefineStatement:
    str.add(node.token.Literal)
    str.add("(" & node.define_name.echoNode() & ")")
    str.add("(" & node.define_value.echoNode() & ")")
  of nkInfixExpression:
    str.add(node.operator)
    if node.left != nil:
      str.add("(" & node.left.echoNode() & ")")
    if node.right != nil:
      str.add("(" & node.right.echoNode() & ")")
  of nkCallExpression:
    str.add(node.function.echoNode())
    for arg in node.args:
      str.add("(" & arg.echoNode() & ")")
  of nkIfExpression:
    str.add("(" & node.condition.echoNode() & ")")
    str.add("{")
    for statement in node.consequence.statements:
      str.add(statement.echoNode())
    str.add("}")
    if node.alternative != nil:
      str.add("{")
      for statement in node.alternative.statements:
        str.add(statement.echoNode())
      str.add("}")
  else:
    return str
  
  return str

when isMainModule:
  var input = """ if (True) {
                    1 + 2
                    4 + 5
                  }
                  else {
                    1 + 3
                  }"""
  var node = makeAST(input)
  echo echoNode(node)
  #echo repr node
