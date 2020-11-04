import ka2token, ka2node, ka2token, ka2error, ka2show

proc makeNewNode(inp_node: Node): Node

proc astShaping*(inp_nodes: seq[Node]): seq[Node] =
  if inp_nodes == @[]:
    return @[]
  
  var out_nodes: seq[Node]

  for inp_node in inp_nodes:
    case inp_node.kind
    # パイプライン演算子
    of nkPipeExpression:
      if inp_node.child_nodes.len() != 2:
        out_nodes.add(makeNewNode(inp_node))
      elif inp_node.child_nodes[1].kind != nkCallExpression:
        out_nodes.add(makeNewNode(inp_node))
      else:
        let element = @[inp_node.child_nodes[0]].astShaping()
        var function = @[inp_node.child_nodes[1]].astShaping()
        function[0].child_nodes[1].child_nodes = element & function[0].child_nodes[1].child_nodes
        var new_node = Node(
          kind:        function[0].kind,
          token:       function[0].token,
          child_nodes: function[0].child_nodes,
        )
        out_nodes.add(new_node)
    of nkMainStatement:
      var main_type = Node(
        kind:        nkIntType,
        token:       Token(Type: T_INT, Literal: "#int"),
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
            token:       Token(Type: T_INT, Literal: "#int"),
            child_nodes: @[Node(kind: nkIdent, token: Token(Type: IDENT, Literal: "argc"),)],
          ),
          Node(
            kind:        nkCharType,
            token:       Token(Type: T_CHAR, Literal: "#char"),
            child_nodes: @[Node(kind: nkIdent, token: Token(Type: IDENT, Literal: "*argv[]"),)],
          )
        ],
      )
      var new_node = Node(
        kind:        nkDefineStatement,
        token:       inp_node.token,
        child_nodes: @[main_type, main_args] & inp_node.child_nodes.astShaping(),
      )
      out_nodes.add(new_node)
    else:
      out_nodes.add(makeNewNode(inp_node))

  return out_nodes

proc makeNewNode(inp_node: Node): Node =
  let new_node = Node(
    kind:        inp_node.kind,
    token:       inp_node.token,
    child_nodes: inp_node.child_nodes.astShaping(),
  )
  return new_node