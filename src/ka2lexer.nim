import pegs

type State = enum
  INITIAL
  COMMENT

proc tokenize(str: string): string =
  if str =~ peg"\d+!\.":      return "INT:"   & str
  elif str =~ peg"\d+\.\d+":  return "FLOAT:" & str
  else:                       return "OTHER:" & str

proc lexer*(code: string): seq[string] =
  var character_stack: string
  var token_list: seq[string]
  var new_token: string = "NIL:"
  var tokenize_flag: bool = false
  var state: State = INITIAL

  for i, character in code:
    case state
    # 初期状態
    of INITIAL:
      # 空白、改行は無視
      if $character =~ peg"\s/\n":    tokenize_flag = true
      # コメント状態に変更
      elif character == '#':          tokenize_flag = true; state = COMMENT
      # OPERATOR
      elif character == '\n':         tokenize_flag = true; new_token = "OPERATOR:EOL"
      elif character == ';':          tokenize_flag = true; new_token = "OPERATOR:EOE"
      elif character == '+':          tokenize_flag = true; new_token = "OPERATOR:ADD"
      elif character == '-':          tokenize_flag = true; new_token = "OPERATOR:SUB"
      elif character == '*':          tokenize_flag = true; new_token = "OPERATOR:MUL"
      elif character == '/':          tokenize_flag = true; new_token = "OPERATOR:DIV"
      elif character == '(':          tokenize_flag = true; new_token = "LPAREN:"
      elif character == ')':          tokenize_flag = true; new_token = "RPAREN:"
      # これら以外ならcharacter_stackに追加
      else:                           character_stack.add(character)
      # character_stackをトークン化してリストに追加
      if tokenize_flag:
        if character_stack != "":
          token_list.add(tokenize(character_stack))
        character_stack = ""
        tokenize_flag = false
      # new_tokenをリストに追加
      if new_token != "NIL:":
        token_list.add(new_token)
        new_token = "NIL:"
      # 最後の文字だった場合
      if i == code.len()-1:
        if character_stack != "":
          token_list.add(tokenize(character_stack))
        character_stack = ""
    # コメント状態
    of COMMENT:
      if character == ';': state = INITIAL
  
  return token_list