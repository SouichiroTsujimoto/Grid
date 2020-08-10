import  ka2parser, ka2token, ka2node

proc echoNode(node: Node): string =
  var str: string = ""
  case node.kind
  of nkIntLiteral:
    str.add($node.intValue)
  of nkBoolLiteral:
    str.add($node.boolValue)
  of nkIdent:
    str.add($node.identValue)
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
  var input = """ if (True) do
                    1 + 2
                    4 + 5
                  end
                  else do
                    1 + 3
                  end"""
  var node = makeAST(input)
  echo echoNode(node)
  #echo repr node

#[
  やること
  ・ LBRACE RBRACEをDO ENDに置き換える ✅
  ・ 真偽値を実装する ✅
  ・ 文字 文字列を実装する
  ・ 小数を実装する
  ・ 関数をちゃんと宣言できるようにする
  ・ c++のコードに変換できるようにする
  ・ elifを実装する
]#