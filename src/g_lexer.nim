import g_token, g_error

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

proc peekChar(l: Lexer): (char, bool) =
  if l.readPosition >= len(l.input):
    return (' ', false)
  else:
    return (l.input[l.readPosition], true)

proc newLexer*(input: string): Lexer =
  var l = Lexer(input: input, line: 1)
  l.nextChar()
  return l

proc isStringHead(ch: char): bool =
  return ('a' <= ch and ch <= 'z') or ('A' <= ch and ch <= 'Z')

proc isLetter(ch: char): bool =
  return ('a' <= ch and ch <= 'z') or ('A' <= ch and ch <= 'Z') or ('0' <= ch and ch <= '9') or ch == '_' or ch == '.'

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

proc escapeChars(c: char): bool =
  case c
  of 'a', 'b', 'n', 'r', 'f', 't', 'v', '\\', '?', '\'', '\"', '0':
    return true
  else:
    return false

proc readChar(l: Lexer): string =
  l.nextChar()
  var c = $l.ch
  l.nextChar()
  if l.ch == '\'' and c != "\\":
    l.nextChar()
    return c
  elif c == "\\":
    if escapeChars(l.ch):
      c = c & $l.ch
      l.nextChar()
      if l.ch == '\'':
        l.nextChar()
        return c
      else:
        echoErrorMessage("文字リテラルの文字が多すぎます", false, l.line)
    else:
      echoErrorMessage("無効なエスケープ文字です", false, l.line)
  else:
    echoErrorMessage("文字リテラルの文字が多すぎます", false, l.line)

proc readString(l: Lexer): string =
  l.nextChar()
  if l.ch == '\"':
    l.nextChar()
    return ""

  var str: string
  while l.ch == '\\' or l.peekChar()[0] != '\"':
    if l.peekChar()[1] == false:
      echoErrorMessage("文字列リテラルが閉じられていません", false, l.line)
    elif l.ch == '\\':
      if escapeChars(l.peekChar()[0]):
        str.add(l.ch)
        l.nextChar()
      else:
        echoErrorMessage("無効なエスケープ文字です", false, l.line)
    else:
      str.add(l.ch)
      l.nextChar()
  str.add(l.ch)

  l.nextChar()
  l.nextChar()

  return str

proc readPreOp(l: Lexer): string =
  l.nextChar()
  if l.ch == '`':
    l.nextChar()
    return ""

  var str: string
  while l.peekChar()[0] != '`':
    if l.peekChar()[1] == false:
      echoErrorMessage("\"`\"が閉じられていません", false, l.line)
    else:
      str.add(l.ch)
      l.nextChar()
  str.add(l.ch)

  l.nextChar()
  l.nextChar()

  return str

proc skipWhitespace(l: Lexer) =
  while (l.ch == ' ' or l.ch == '\t') and l.input.len() > l.position:
    l.nextChar()

proc nextToken*(l: Lexer): Token =
  var tok: Token
  l.skipWhitespace()

  case l.ch
  of '=':
    if l.peekChar()[0] == '=':
      let ch = l.ch
      l.nextChar()
      let literal = $ch & $l.ch
      tok = Token(Type: EE, Literal: literal, Line: l.line)
    else:
      tok = Token(Type: EQUAL, Literal: $l.ch, Line: l.line)
  of '!': 
    if l.peekChar()[0] == '=':
      let ch = l.ch
      l.nextChar()
      let literal = $ch & $l.ch
      tok = Token(Type: NE, Literal: literal, Line: l.line)
    else:
      tok = Token(Type: NOT, Literal: $l.ch, Line: l.line)
  of '<':
    if l.peekChar()[0] == '=':
      let ch = l.ch
      l.nextChar()
      let literal = $ch & $l.ch
      tok = Token(Type: LTE, Literal: literal, Line: l.line)
    elif l.peekChar()[0] == '-':
      let ch = l.ch
      l.nextChar()
      let literal = $ch & $l.ch
      tok = Token(Type: LARROW, Literal: literal, Line: l.line)
    else:
      tok = Token(Type: LT, Literal: $l.ch, Line: l.line)
  of '>':
    if l.peekChar()[0] == '=':
      let ch = l.ch
      l.nextChar()
      let literal = $ch & $l.ch
      tok = Token(Type: GTE, Literal: literal, Line: l.line)
    else:
      tok = Token(Type: GT, Literal: $l.ch, Line: l.line)
  of '|':
    if l.peekChar()[0] == '>':
      let ch = l.ch
      l.nextChar()
      let literal = $ch & $l.ch
      tok = Token(Type: PIPE, Literal: literal, Line: l.line)
    else:
      tok = Token(Type: VERTICAL, Literal: $l.ch, Line: l.line)
  of '-' :
    if l.peekChar()[0] == '>':
      let ch = l.ch
      l.nextChar()
      let literal = $ch & $l.ch
      tok = Token(Type: RARROW, Literal: literal, Line: l.line)
    else:
      tok = Token(Type: MINUS, Literal: $l.ch, Line: l.line)
  of '/' :
    if l.peekChar()[0] == '*':
      let ch = l.ch
      l.nextChar()
      let literal = $ch & $l.ch
      tok = Token(Type: COMMENTBEGIN, Literal: literal, Line: l.line)
    else:
      tok = Token(Type: SLASH, Literal: $l.ch, Line: l.line)
  of '*' :
    if l.peekChar()[0] == '/':
      let ch = l.ch
      l.nextChar()
      let literal = $ch & $l.ch
      tok = Token(Type: COMMENTEND, Literal: literal, Line: l.line)
    else:
      tok = Token(Type: ASTERISC, Literal: $l.ch, Line: l.line)
  of '+' : tok = Token(Type: PLUS, Literal: $l.ch, Line: l.line)
  of '(' : tok = Token(Type: LPAREN, Literal: $l.ch, Line: l.line)
  of ')' : tok = Token(Type: RPAREN, Literal: $l.ch, Line: l.line)
  of '[' : tok = Token(Type: LBRACKET, Literal: $l.ch, Line: l.line)
  of ']' : tok = Token(Type: RBRACKET, Literal: $l.ch, Line: l.line)
  of ',' : tok = Token(Type: COMMA, Literal: $l.ch, Line: l.line)
  of '{' : tok = Token(Type: LBRACE, Literal: $l.ch, Line: l.line)
  of '}' : tok = Token(Type: RBRACE, Literal: $l.ch, Line: l.line)
  of ':' : tok = Token(Type: COLON, Literal: $l.ch, Line: l.line)
  of '$' : tok = Token(Type: DOLLAR, Literal: $l.ch, Line: l.line)
  of '&' : tok = Token(Type: AMPERSAND, Literal: $l.ch, Line: l.line)
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
    elif l.ch == '`':
      let lit = l.readPreOp()
      return Token(Type: PREOP, Literal: lit, Line: l.line)
    elif l.ch.isDigit():
      let (lit, decimal) = l.readNumber
      if decimal:
        return Token(Type: FLOAT, Literal: lit, Line: l.line)
      else:
        return Token(Type: INT, Literal: lit, Line: l.line)
    elif l.ch.isStringHead():
      let lit = l.readIdent()
      let typ = LookupIdent(lit)
      return Token(Type: typ, Literal: lit, Line: l.line)
    elif l.ch.isLetter():
      echoErrorMessage("名前の一文字目に使用できる文字はa-zもしくはA-Zのみです", false, l.line)
    else:
      if l.input.len()-1 <= l.position:
        tok = Token(Type: EOF, Literal: $l.ch, Line: l.line)
      else:
        tok = Token(Type: ILLEGAL, Literal: $l.ch, Line: l.line)
  
  l.nextChar()
  return tok