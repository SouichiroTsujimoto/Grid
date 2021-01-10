import ka2token

type Lexer* = ref object of RootObj
  input:        string
  position:     int
  line:         int
  readPosition: int
  ch:           char

proc nextLine(l: Lexer) =
  l.line = l.line + 1

proc nextChar(l: Lexer) =
  if l.readPosition >= len(l.input):
    l.ch = ' '
  else:
    l.ch = l.input[l.readPosition]
  l.position = l.readPosition
  l.readPosition += 1

proc peekChar(l: Lexer): char =
  if l.readPosition >= len(l.input):
    return ' '
  else:
    return l.input[l.readPosition]

proc newLexer*(input: string): Lexer =
  var l = Lexer(input: input, line: 1)
  l.nextChar()
  return l

proc isStringHead(ch: char): bool =
  return ('a' <= ch and ch <= 'z') or ('A' <= ch and ch <= 'Z') or ch == '#'

proc isLetter(ch: char): bool =
  return ('a' <= ch and ch <= 'z') or ('A' <= ch and ch <= 'Z') or ch == '_' or ch == '#'

proc isDigit(ch: char): bool =
  return '0' <= ch and ch <= '9'

proc readIdent(l: Lexer): string =
  let position = l.position
  while isLetter(l.ch):
    l.nextChar()
  return l.input[position..l.position-1]

proc readNumber(l: Lexer): (string, bool) =
  let position = l.position
  while isDigit(l.ch):
    l.nextChar()
  if l.ch == '.':
    l.nextChar()
    while isDigit(l.ch):
      l.nextChar()
    return (l.input[position..l.position-1], true)
  else:
    return (l.input[position..l.position-1], false)

proc readChar(l: Lexer): string =
  l.nextChar()
  if l.ch != '\'':
    let c = $l.ch
    l.nextChar()
    l.nextChar()
    return c
  else:
    l.nextChar()
    return ""

proc readString(l: Lexer): string =
  l.nextChar()
  var str: string
  while l.ch != '\"':
    str.add(l.ch)
    l.nextChar()
  l.nextChar()
  return str

proc readCppCode(l: Lexer): string =
  l.nextChar()
  var cppCode: string
  while l.ch != '}':
    cppCode.add(l.ch)
    l.nextChar()
  l.nextChar()
  return cppCode

proc skipWhitespace(l: Lexer) =
  while (l.ch == ' ' or l.ch == '\t') and l.input.len() > l.position:
    l.nextChar()

proc nextToken*(l: Lexer): Token =
  var tok: Token
  l.skipWhitespace()

  case l.ch
  of '=':
    if l.peekChar() == '=':
      let ch = l.ch
      l.nextChar()
      let literal = $ch & $l.ch
      tok = Token(Type: EE, Literal: literal, Line: l.line)
    else:
      tok = Token(Type: EQUAL, Literal: $l.ch, Line: l.line)
  of '!': 
    if l.peekChar() == '=':
      let ch = l.ch
      l.nextChar()
      let literal = $ch & $l.ch
      tok = Token(Type: NE, Literal: literal, Line: l.line)
    elif l.peekChar() == '!':
      let ch = l.ch
      l.nextChar()
      let literal = $ch & $l.ch
      tok = Token(Type: INDEX, Literal: literal, Line: l.line)
    else:
      tok = Token(Type: NOT, Literal: $l.ch, Line: l.line)
  of '<':
    if l.peekChar() == '=':
      let ch = l.ch
      l.nextChar()
      let literal = $ch & $l.ch
      tok = Token(Type: LE, Literal: literal, Line: l.line)
    elif l.peekChar() == '-':
      let ch = l.ch
      l.nextChar()
      let literal = $ch & $l.ch
      tok = Token(Type: ARROW, Literal: literal, Line: l.line)
    else:
      tok = Token(Type: LT, Literal: $l.ch, Line: l.line)
  of '>':
    if l.peekChar() == '=':
      let ch = l.ch
      l.nextChar()
      let literal = $ch & $l.ch
      tok = Token(Type: GE, Literal: literal, Line: l.line)
    else:
      tok = Token(Type: GT, Literal: $l.ch, Line: l.line)
  of '|':
    if l.peekChar() == '>':
      let ch = l.ch
      l.nextChar()
      let literal = $ch & $l.ch
      tok = Token(Type: PIPE, Literal: literal, Line: l.line)
    else:
      echo "エラ〜〜〜 : '|'"
  of '-' :
    tok = Token(Type: MINUS, Literal: $l.ch, Line: l.line)
    # if l.peekChar().isDigit():
    #   l.nextChar()
    #   let (lit, decimal) = l.readNumber
    #   if decimal:
    #     return Token(Type: FLOAT, Literal: "-" & lit, Line: l.line)
    #   else:
    #     return Token(Type: INT, Literal: "-" & lit, Line: l.line)
    # else:
    #   tok = Token(Type: MINUS, Literal: $l.ch, Line: l.line)
  of '/' :
    if l.peekChar() == '*':
      let ch = l.ch
      l.nextChar()
      let literal = $ch & $l.ch
      tok = Token(Type: COMMENTBEGIN, Literal: literal, Line: l.line)
    else:
      tok = Token(Type: SLASH, Literal: $l.ch, Line: l.line)
  of '*' :
    if l.peekChar() == '/':
      let ch = l.ch
      l.nextChar()
      let literal = $ch & $l.ch
      tok = Token(Type: COMMENTEND, Literal: literal, Line: l.line)
    else:
      tok = Token(Type: ASTERISC, Literal: $l.ch, Line: l.line)
  of '+' : tok = Token(Type: PLUS, Literal: $l.ch, Line: l.line)
  of '(' : tok = Token(Type: LPAREN, Literal: $l.ch, Line: l.line)
  of ')' : tok = Token(Type: RPAREN, Literal: $l.ch, Line: l.line)
  of ',' : tok = Token(Type: COMMA, Literal: $l.ch, Line: l.line)
  of '{' : tok = Token(Type: LBRACE, Literal: $l.ch, Line: l.line)
  of '}' : tok = Token(Type: RBRACE, Literal: $l.ch, Line: l.line)
  of ':' : tok = Token(Type: COLON, Literal: $l.ch, Line: l.line)
  else:
    if l.ch == '\n':
      l.nextLine()
      l.nextChar()
      return l.nextToken()
    elif l.ch == '\'':
      let lit = l.readChar()
      return Token(Type: CHAR, Literal: lit, Line: l.line)
    elif l.ch == '\"':
      let lit = l.readString()
      return Token(Type: STRING, Literal: lit, Line: l.line)
    elif l.ch.isStringHead():
      let lit = l.readIdent()
      let typ = LookupIdent(lit)
      return Token(Type: typ, Literal: lit, Line: l.line)
    elif l.ch.isDigit():
      let (lit, decimal) = l.readNumber
      if decimal:
        return Token(Type: FLOAT, Literal: lit, Line: l.line)
      else:
        return Token(Type: INT, Literal: lit, Line: l.line)
    elif l.ch.isLetter():
      echo "エラ〜〜〜 : '_'から始まっています"
      quit()
    else:
      if l.input.len()-1 <= l.position:
        tok = Token(Type: EOF, Literal: $l.ch, Line: l.line)
      else:
        tok = Token(Type: ILLEGAL, Literal: $l.ch, Line: l.line)
  
  l.nextChar()
  return tok