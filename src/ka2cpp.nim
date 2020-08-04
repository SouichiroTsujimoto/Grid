import tables, strutils, algorithm

proc tokenToCpp(token_type: string, token_content: string): (char, int, string) =
  case token_type:
  of "INT", "FLOAT":
    return ('v', 0, "(" & token_content & ")")
  of "OPERATOR", "OTHER":
    case token_content
    of "ADD":
      return ('f', 2, "ka2_add")
    of "SUB":
      return ('f', 2, "ka2_sub")
    of "MUL":
      return ('f', 2, "ka2_mul")
    of "DIV":
      return ('f', 2, "ka2_div")
  of "EXPR":
    return ('e', 0, token_content)

proc makeCppCodeParts*(key: string, exprs: Table[string, seq[string]]): string =
  var cpp_code_parts: seq[string]
  var cpp_value_stack: seq[string]
  var token_type, token_content: string
  var fve: char
  var arg_number: int
  var content: string
  var value_buffer: seq[string]
  
  for token in exprs[key]:
    (token_type, token_content) = token.split(":")
    (fve, arg_number, content) = tokenToCpp(token_type, token_content)
    if fve == 'f':
      cpp_code_parts.add(content)
      for i in 1..arg_number:
        if cpp_value_stack.len() != 0:
          value_buffer.add(cpp_value_stack.pop)
        else:
          break
      cpp_code_parts.add(value_buffer.reversed)
      value_buffer = @[]
    elif fve == 'v':
      cpp_value_stack.add(content)
    elif fve == 'e':
      cpp_value_stack.add("(" & makeCppCodeParts(content, exprs) & ")")

  return cpp_code_parts.join(" ")
