import pegs, strutils, sequtils

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
        expr_list.add(exprReplace(parent_numbers & "-" & $number, token_stack))
        expr_list[0][1].add("EXPR:" & parent_numbers & "-" & $number)
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

#[
↑↑↑↑ヨシ！↑↑↑↑
　　　 ∧　　/ヽ
　　　/／￣￣＼|
　　 ∠＿╋＿＿〉
　　/　①八①　ヽ ＿
　 工ﾆf(_人_)ｴ二|′)ヽ
　　＼ヽヽノノ ノ ヘ |
⊂⌒)_＞―――′イ (＿)
　`ー､_ノ/￣ヽ　｜
　　 ＿|｜　 |　｜
　　(　 人＿ノ　Λ
　　 ＼ス￣￣ﾚ-Λ ＼
　　(￣　)　/ /　＼ﾉ＼
　　 ￣￣　(　ヽ　 ＼_)
　　　　　　＼ノ
]#


proc parser*(token_list: seq[string]): seq[string] =

  # まず括弧の処理
  for exprs in exprReplace("0", token_list):
    echo exprs
  # 演算子を前に

  # 式を合体


  return token_list