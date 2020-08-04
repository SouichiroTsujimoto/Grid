import strutils, tables

# 括弧の処理
proc exprReplace(parent_numbers: string, token_list: seq[string]): seq[(string, seq[string])] =
  var nesting_count = 0
  var token_stack: seq[string]
  var expr_list: seq[(string, seq[string])]
  var number = 0
  expr_list.add((parent_numbers, @[]))

  for token in token_list:
    # 開き括弧
    if token == "LPAREN:":
      if nesting_count != 0:
        token_stack.add(token)
      nesting_count = nesting_count + 1
    # 閉じ括弧
    elif token == "RPAREN:":
      if nesting_count == 1:
        number = number + 1
        expr_list.add(exprReplace(parent_numbers & "_" & $number, token_stack))
        expr_list[0][1].add("EXPR:" & parent_numbers & "_" & $number)
        token_stack = @[]
      else:
        token_stack.add(token)
      nesting_count = nesting_count - 1
    # 括弧が開いている場合
    elif nesting_count != 0:
      token_stack.add(token)
    # 括弧が開いていない場合
    else:
      expr_list[0][1].add(token)
  
  return expr_list

proc checkPrecedence(token_content: string): int =
  case token_content
  of "EOE", "EOL":  return 1
  of "ADD", "SUB":  return 2
  of "MUL", "DIV":  return 3
  else:             return -1

proc transformExpr(tree: seq[(string, seq[string])]): seq[(string, seq[string])] =
  var t_t, t_c: string
  var token_stack: seq[string]
  var operator_token_stack: seq[string]
  var pop: string
  var new_tree: seq[(string, seq[string])]
  # 反転させた式を後置記法に
  for (node_number, node_expr) in tree:
    for token in node_expr:
      # TODO注意
      (t_t, t_c) = token.split(":")
      case t_t
      of "INT", "FLOAT", "EXPR":
        token_stack.add(token)
      of "OTHER":
        while true:
          # スタックが空なら無条件で追加
          if operator_token_stack.len == 0:
            operator_token_stack.add(token)
            break
          # スタックの最後の要素と比較
          pop = operator_token_stack.pop
          if checkPrecedence(pop.split(":")[1]) >= 0:
            token_stack.add(pop)
          else:
            operator_token_stack.add(pop)
            operator_token_stack.add(token)
            break
      of "OPERATOR":
        while true:
          # スタックが空なら無条件で追加
          if operator_token_stack.len == 0:
            operator_token_stack.add(token)
            break
          # スタックの最後の要素と比較
          pop = operator_token_stack.pop
          if checkPrecedence(pop.split(":")[1]) >= checkPrecedence(t_c):
            token_stack.add(pop)
          else:
            operator_token_stack.add(pop)
            operator_token_stack.add(token)
            break
    # 残った演算子をtoken_stackに追加
    while true:
      if operator_token_stack.len != 0:
        token_stack.add(operator_token_stack.pop)
      else:
        break
    new_tree.add((node_number, token_stack))
    token_stack = @[]
    operator_token_stack = @[]

  return new_tree

proc parser*(token_list: seq[string]): Table[string, seq[string]] =
  var exprs: seq[(string, seq[string])]
  # まず括弧の処理
  exprs = exprReplace("0", token_list)
  # 演算子を前に
  exprs = transformExpr(exprs)

  return exprs.toTable