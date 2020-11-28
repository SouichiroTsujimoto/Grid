import ka2parser, ka2rw, ka2node, ka2cpp, ka2shaping

proc showAST*(node: Node, indent: int): string =
  if node.kind != nkNil:
    result.add("{kind: " & $node.kind & ", (Type:" & $node.token.Type & ", Literal:" & $node.token.Literal & "), [")
    for child in node.child_nodes:
      result.add("\n")
      for i in 0..indent:
        result.add("  ")
      result.add(showAST(child, indent + 1))
  
  if node.child_nodes != @[]:
    for i in 0..indent-1:
      result.add("  ")
    result.add("]}\n")
  else:
    result.add("]}\n")