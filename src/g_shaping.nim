import g_token, g_node, g_token, g_error

proc makeNewNode(inp_node: Node, main_flag: bool, test: bool): (Node, bool)

proc astShaping*(inp_nodes: seq[Node], main_flag: bool, test: bool): (seq[Node], bool) =
  if inp_nodes == @[]:
    return (@[], main_flag)
  
  var out_nodes: seq[Node]
  var new_main_flag = main_flag

  for inp_node in inp_nodes:
    case inp_node.kind
    # main文が二度記述されていないかチェック
    of nkMainStatement:
      if new_main_flag == false:
        new_main_flag = true
      else:
        echoErrorMessage("main文が二度記述されています", test, -1)

      var main_type = Node(
        kind:        nkIntType,
        token:       Token(Type: T_INT, Literal: "int"),
        child_nodes: @[
          Node(kind: nkIdent, token: Token(Type: IDENT, Literal: "main"), child_nodes: @[])
        ],
      )
      var main_args = Node(
        kind:        nkArgs,
        token:       Token(Type: "(", Literal: "("),
        child_nodes: @[
          Node(
            kind:        nkIntType,
            token:       Token(Type: T_INT, Literal: "int"),
            child_nodes: @[Node(kind: nkIdent, token: Token(Type: IDENT, Literal: "argc"),)],
          ),
          Node(
            kind:        nkCharType,
            token:       Token(Type: T_CHAR, Literal: "char"),
            child_nodes: @[Node(kind: nkIdent, token: Token(Type: IDENT, Literal: "*argv[]"),)],
          )
        ],
      )
      var res = inp_node.child_nodes.astShaping(new_main_flag, test)
      new_main_flag = res[1]
      var new_node = Node(
        kind:        nkMainStatement,
        token:       inp_node.token,
        child_nodes: @[main_type, main_args] & res[0],
      )
      out_nodes.add(new_node)

    # '$'をtoString関数の形に変形
    of nkDollarExpression:
      if inp_node.child_nodes.len() != 0:
        var res0 = inp_node.child_nodes.astShaping(new_main_flag, test)
        let target = res0[0]
        new_main_flag = res0[1]

        var new_node = Node(
          kind:        nkCallExpression,
          token:       Token(Type: LPAREN, Literal: "()"),
          child_nodes: @[
          Node(
            kind: nkIdent,
            token: Token(Type: IDENT, Literal: "toString"),
            child_nodes: @[],
          ),
          Node(
            kind: nkArgs,
            token: Token(Type: LPAREN, Literal: "()"),
            child_nodes: target,
          )],
        )
        out_nodes.add(new_node)
      else:
        echoErrorMessage("'$'の後ろに対象がありません", test, inp_node.token.Line)

    # パイプライン演算子を前置記法の関数の形に変形
    of nkPipeExpression:
      if inp_node.child_nodes.len() != 2:
        echoErrorMessage("\"|>\"のオペランドが間違っています", test, inp_node.token.Line)
      elif inp_node.child_nodes[1].kind == nkCallExpression or inp_node.child_nodes[1].kind == nkMapFunction:
        var res0 = @[inp_node.child_nodes[0]].astShaping(new_main_flag, test)
        let element = res0[0]
        new_main_flag = res0[1]
        var res1 = @[inp_node.child_nodes[1]].astShaping(new_main_flag, test)
        let function = res1[0]
        new_main_flag = res1[1]

        function[0].child_nodes[1].child_nodes = element & function[0].child_nodes[1].child_nodes
        var new_node = Node(
          kind:        function[0].kind,
          token:       function[0].token,
          child_nodes: function[0].child_nodes,
        )
        out_nodes.add(new_node)
      else:
        echoErrorMessage("\"|>\"のオペランドが間違っています", test, inp_node.token.Line)
    else:
      var new_node = makeNewNode(inp_node, new_main_flag, test)
      new_main_flag = new_node[1]
      out_nodes.add(new_node[0])

  return (out_nodes, new_main_flag)

proc makeNewNode(inp_node: Node, main_flag: bool, test: bool): (Node, bool) =
  var new_main_flag: bool
  var res = inp_node.child_nodes.astShaping(main_flag, test)
  new_main_flag = res[1]
  let new_node = Node(
    kind:        inp_node.kind,
    token:       inp_node.token,
    child_nodes: res[0],
  )
  return (new_node, new_main_flag)