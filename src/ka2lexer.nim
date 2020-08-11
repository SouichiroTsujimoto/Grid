import ka2token

type Lexer* = ref object of RootObj
  input: string
  position: int
  readPosition: int
  ch: char

proc newToken(tokenType: string, ch: char): Token =
  return Token(Type: tokenType, Literal: $ch)

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
  var l = Lexer(input: input)
  l.nextChar()
  return l

proc isLetter(ch: char): bool =
  return ('a' <= ch and ch <= 'z') or ('A' <= ch and ch <= 'Z') or ch == '_'

# TODO 小数
proc isDigit(ch: char): bool =
  return ('0' <= ch and ch <= '9') or ch == '.'

# TODO バックスラッシュ
proc isSingleQuote(ch: char): bool =
  return ch == '\''

proc isDoubleQuote(ch: char): bool =
  return ch == '\"'

proc readIdent(l: Lexer): string =
  let position = l.position
  while isLetter(l.ch):
    l.nextChar()
  return l.input[position..l.position-1]

proc readNumber(l: Lexer): string =
  let position = l.position
  while isDigit(l.ch):
    l.nextChar()
  return l.input[position..l.position-1]

proc readChar(l: Lexer): string =
  l.nextChar()
  if l.ch.isSingleQuote == false:
    let c = $l.ch
    l.nextChar()
    return c
  else:
    l.nextChar()
    return ""

proc readString(l: Lexer): string =
  l.nextChar()
  var str: string
  while l.ch.isDoubleQuote == false:
    str.add(l.ch)
    l.nextChar()
  l.nextChar()
  return str

proc skipWhitespace(l: Lexer) =
  while (l.ch == ' ' or l.ch == '\t' or l.ch == '\n') and l.input.len() > l.position:
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
      tok = Token(Type: EQ, Literal: literal)
    else:
      tok = newToken(ASSIGN, l.ch)
  of '|':
    if l.peekChar() == '>':
      let ch = l.ch
      l.nextChar()
      let literal = $ch & $l.ch
      tok = Token(Type: PIPE, Literal: literal)
  of ';' : tok = newToken(SEMICOLON, l.ch)
  of '(' : tok = newToken(LPAREN, l.ch)
  of ')' : tok = newToken(RPAREN, l.ch)
  of ',' : tok = newToken(COMMA, l.ch)
  of '+' : tok = newToken(PLUS, l.ch)
  of '-' : tok = newToken(MINUS, l.ch)
  of '*' : tok = newToken(ASTERISC, l.ch)
  of '/' : tok = newToken(SLASH, l.ch)
  of '<' : tok = newToken(LT, l.ch)
  of '>' : tok = newToken(GT, l.ch)
  else:
    if l.ch.isSingleQuote:
      let lit = l.readChar()
      return Token(Type: CHAR, Literal: lit)
    elif l.ch.isDoubleQuote:
      let lit = l.readString()
      return Token(Type: STRING, Literal: lit)
    elif l.ch.isLetter():
      let lit = l.readIdent()
      let typ = LookupIdent(lit)
      return Token(Type: typ, Literal: lit)
    elif l.ch.isDigit():
      let lit = l.readNumber
      let typ = INT
      return Token(Type: typ, Literal: lit)
    else:
      tok = newToken(ILLEGAL, l.ch)
  
  l.nextChar()
  return tok