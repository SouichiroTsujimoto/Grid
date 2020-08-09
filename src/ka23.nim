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
  else:
    return str
  
  return str

when isMainModule:
  var input = """def a = 1 + 2 + 3;"""
  var node = makeAST(input)
  echo echoNode(node)
  #echo repr node
