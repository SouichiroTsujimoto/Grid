import  ka2parser, ka2rw, ka2node, ka2cpp, ka2shaping

proc showAST(node: Node, indent: int): string =
  for i in 0..indent-1:
    result.add("  ")
  result.add("{:" & $node.kind & ", [Type:" & $node.token.Type & ", Literal:" & $node.token.Literal & "], [")
  for child in node.child_nodes:
    result.add("\n")
    result.add(showAST(child, indent + 1))
  
  for i in 0..indent-1:
    result.add("  ")
  result.add("]}\n")

proc showASTs*(nodes: seq[Node]): string =
  for node in nodes:
    result.add(showAST(node, 0))