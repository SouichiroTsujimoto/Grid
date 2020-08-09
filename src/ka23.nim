import  ka2parser, ka2cpp, ka2token, ka2node

proc echoNode(node: Node): string =
  var str: string = ""
  case node.node_kind
  of nkIntLiteral:
    str.add(node.token.Literal)
  of nkIdent:
    str.add(node.token.Literal)
  of nkInfixExpression:
    str.add(node.operator)
    if node.left != nil:
      str.add("(" & node.left.echoNode & ")")
    if node.right != nil:
      str.add("(" & node.right.echoNode & ")")
  of nkCallExpression:
    str.add(node.function.echoNode)
    for arg in node.args:
      str.add("(" & arg.echoNode & ")")
  else:
    return str
  
  return str

when isMainModule:
  var input = """puts(s)"""
  var node = makeAST(input)
  echo echoNode(node)
  #echo repr node
