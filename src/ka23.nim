import  ka2parser, ka2token, ka2node

proc echoNode(node: Node): string =
  var str: string = ""
  case node.kind
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
  of nkIdent:
    str.add($node.identValue)
  of nkLetStatement:
    str.add(node.token.Literal)
    str.add("(" & node.let_name.echoNode() & ")")
    str.add("(" & node.let_value.echoNode() & ")")
  of nkDefineStatement:
    str.add(node.token.Literal)
    str.add("<" & node.define_name.echoNode())
    for arg in node.define_args:
      str.add("[" & arg.echoNode() & "]")
    str.add(">")
    str.add("{")
    for statement in node.define_block.statements:
      str.add(statement.echoNode())
    str.add("}")
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
    str.add("if")
    str.add("(" & node.condition.echoNode() & ")")
    str.add("{")
    for statement in node.consequence.statements:
      str.add(statement.echoNode())
    str.add("}")
  of nkIfAndElseExpression:
    str.add("if")
    str.add("(" & node.condition.echoNode() & ")")
    str.add("{")
    for statement in node.consequence.statements:
      str.add(statement.echoNode())
    str.add("}")
    str.add("else")
    str.add("{")
    for statement in node.alternative.statements:
      str.add(statement.echoNode())
    str.add("}")
  else:
    return str
  
  return str

when isMainModule:
  var input = """ def nibai(x) = do
                    x * 2
                  end"""
  var node = makeAST(input)
  echo echoNode(node)
  #echo repr node

#[
  TODO
  ・ 関数をちゃんと宣言できるようにする
  ・ c++のコードに変換できるようにする
  ・ elifを実装する
  ・ 比較演算子を実装する
]#