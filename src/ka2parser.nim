import strutils
import ka2token, ka2lexer, ka2node

# パーサクラス
type Parser = ref object of RootObj
  lexer: Lexer
  curToken: Token
  peekToken: Token
  errors: string

# プロトタイプ宣言
proc parseExpression(p: Parser, precedence: Precedence): Node
proc parseStatement(p: Parser): Node
proc parseBlockStatement(p: Parser, endTokenTypes: seq[string]): BlockStatement
proc parseCallExpression(p: Parser, left: Node): Node
proc parseExpressionList(p: Parser, endToken: string): seq[Node]
proc parseType(p: Parser): Node
proc parseNameProc(p: Parser, endToken: string): seq[Node]

# パーサクラスのインスタンスを作る
proc newParser(l: Lexer): Parser =
  let p = Parser(
    lexer: l,
    curToken: l.nextToken(),
    peekToken: l.nextToken(),
  )
  return p

# curTokenとpeekTokenを一つ進める
proc shiftToken(p: Parser) =
  p.curToken = p.peekToken
  p.peekToken = p.lexer.nextToken()

# 変数定義
proc parseLetStatement(p: Parser): Node =
  var node = Node(
    kind: nkLetStatement,
    token: p.curToken,
  )
  p.shiftToken()
  node.let_ident = p.parseType()

  if p.peekToken.Type != ASSIGN:
    return node
  
  p.shiftToken()
  p.shiftToken()
  node.let_value = p.parseExpression(Lowest)

  return node

# return文
proc parseReturnStatement(p: Parser): Node =
  var node = Node(
    kind: nkReturnStatement,
    token: p.curToken,
  )
  p.shiftToken()
  node.return_expression = p.parseExpression(Lowest)
  return node

# 関数定義
# 引数無しに対応させろ
# 引数に型を付けさせろ
# TODO
proc parseDefineStatement(p: Parser): Node =
  var node = Node(
    kind: nkDefineStatement,
    token: p.curToken,
  )
  p.shiftToken()
  node.define_ident = p.parseType()
  if p.peekToken.Type != LPAREN:
    return Node(kind: nkNil)
  p.shiftToken()
  node.define_args = p.parseNameProc(RPAREN)

  if p.peekToken.Type != DO:
    return Node(kind: nkNil)
  p.shiftToken()

  node.define_block = p.parseBlockStatement(@[END])
  if p.peekToken.Type != END:
    return Node(kind: nkNil)

  p.shiftToken()
  return node

# 中置演算子の処理
proc parseInfixExpression(p: Parser, left: Node): Node =
  let operator = p.curToken.Type
  let cp = p.curToken.tokenPrecedence()
  p.shiftToken()
  let right = p.parseExpression(cp)
  let node = Node(
    kind: nkInfixExpression,
    token: p.curToken,
    operator: operator,
    left: left,
    right: right,
  )
  return node

# 引数の処理
# TODO
proc parseExpressionList(p: Parser, endToken: string): seq[Node] =
  var list = newSeq[Node]()
  if p.peekToken.Type == endToken:
    p.shiftToken()
    return list

  p.shiftToken()
  list.add(p.parseExpression(Lowest))

  while p.peekToken.Type == COMMA:
    p.shiftToken()
    p.shiftToken()
    list.add(p.parseExpression(Lowest))

  p.shiftToken()
  return list

# 宣言の処理
proc parseNameProc(p: Parser, endToken: string): seq[Node] =
  var list = newSeq[Node]()
  if p.peekToken.Type == endToken:
    p.shiftToken()
    return list

  p.shiftToken()
  list.add(p.parseType())

  while p.peekToken.Type == COMMA:
    p.shiftToken()
    p.shiftToken()
    list.add(p.parseType())

  p.shiftToken()
  return list

# 関数呼び出しの処理
proc parseCallExpression(p: Parser, left: Node): Node =
  var node = Node(
    kind: nkCallExpression,
    token:     p.curToken,
    function:  left,
  )
  p.shiftToken()
  node.args = p.parseExpressionList(RPAREN)
  return node
  # TODO

# 名前
proc parseIdent(p: Parser): Node =
  let node = Node(
    kind: nkIdent,
    token: p.curToken,
    identValue: p.curToken.Literal,
  )
  return node

# 整数値リテラル
proc parseIntLiteral(p: Parser): Node =
  let node = Node(
    kind: nkIntLiteral,
    token: p.curToken,
    intValue: p.curToken.Literal.parseInt()
  )
  return node

# 小数値リテラル
proc parseFloatLiteral(p: Parser): Node =
  let node = Node(
    kind: nkFloatLiteral,
    token: p.curToken,
    floatValue: p.curToken.Literal.parseFloat()
  )
  return node

# 文字リテラル
proc parseCharLiteral(p: Parser): Node =
  let node = Node(
    kind: nkCharLiteral,
    token: p.curToken,
    charValue: p.curToken.Literal[0],
  )
  return node

# 文字列リテラル
proc parseStringLiteral(p: Parser): Node =
  let node = Node(
    kind: nkStringLiteral,
    token: p.curToken,
    stringValue: p.curToken.Literal,
  )
  return node

# 真偽値リテラル
proc parseBoolLiteral(p: Parser): Node =
  let node = Node(
    kind: nkBoolLiteral,
    token: p.curToken,
    boolValue: p.curToken.Literal.parseBool()
  )
  return node

# nil値
proc parseNilLiteral(p: Parser): Node =
  let node = Node(
    kind: nkNilLiteral,
    token: p.curToken,
  )
  return node

# int型
proc parseIntType(p: Parser): Node =
  var node = Node(
    kind: nkIntType,
    token: p.curToken,
    typeValue: p.curToken.Literal,
  )
  if p.peekToken.Type == IDENT:
    p.shiftToken()
    node.identValue = p.curToken.Literal
  return node

# float型
proc parseFloatType(p: Parser): Node =
  let node = Node(
    kind: nkFloatType,
    token: p.curToken,
    typeValue: p.curToken.Literal,
  )
  if p.peekToken.Type == IDENT:
    p.shiftToken()
    node.identValue = p.curToken.Literal
  return node

# char型
proc parseCharType(p: Parser): Node =
  let node = Node(
    kind: nkCharType,
    token: p.curToken,
    typeValue: p.curToken.Literal,
  )
  if p.peekToken.Type == IDENT:
    p.shiftToken()
    node.identValue = p.curToken.Literal
  return node

# string型
proc parseStringType(p: Parser): Node =
  let node = Node(
    kind: nkStringType,
    token: p.curToken,
    typeValue: p.curToken.Literal,
  )
  if p.peekToken.Type == IDENT:
    p.shiftToken()
    node.identValue = p.curToken.Literal
  return node

# if文
proc parseIfExpression(p: Parser): Node =
  var node = Node(
    kind: nkIfExpression,
    token: p.curToken,
  )
  p.shiftToken()
  node.condition = p.parseExpression(Lowest)
  if p.peekToken.Type != DO:
    return Node(kind: nkNil)
  p.shiftToken()
  node.consequence = p.parseBlockStatement(@[END, ELIF, ELSE])

  # elifがあった場合
  if p.peekToken.Type == ELIF:
    p.shiftToken()
    let res = p.parseIfExpression
    node.alternative = Node(
      kind: nkElifExpression,
      token: p.curToken,
      condition: res.condition,
      consequence: res.consequence,
      alternative: res.alternative,
    )
    p.shiftToken()
    return node
  # elseがあった場合
  elif p.peekToken.Type == ELSE:
    p.shiftToken()
    node.alternative = Node(
      kind: nkElseExpression,
      token: p.curToken,
      consequence: p.parseBlockStatement(@[END]),
    )
    p.shiftToken()
    return node
  # endの場合
  elif p.peekToken.Type == END:
    p.shiftToken()
    return node

proc parseGroupedExpression(p: Parser): Node =
  p.shiftToken()
  let node = p.parseExpression(Lowest)
  if p.peekToken.Type == RPAREN:
    return node
  else:
    return nil

proc parseType(p: Parser): Node =
  case p.curToken.Type
  of T_INT      : return p.parseIntType()
  of T_FLOAT    : return p.parseFloatType()
  of T_CHAR     : return p.parseCharType()
  of T_STRING   : return p.parseStringType()
  else          : return nil

# 式の処理
proc parseExpression(p: Parser, precedence: Precedence): Node =
  var left: Node
  case p.curToken.Type
  of IF         : left = p.parseIfExpression()
  of RETURN     : left = p.parseReturnStatement()
  of IDENT      : left = p.parseIdent()
  of INT        : left = p.parseIntLiteral()
  of FLOAT      : left = p.parseFloatLiteral()
  of CHAR       : left = p.parseCharLiteral()
  of STRING     : left = p.parseStringLiteral()
  of TRUE       : left = p.parseBoolLiteral()
  of FALSE      : left = p.parseBoolLiteral()
  of NIL        : left = p.parseNilLiteral()
  of LPAREN     : left = p.parseGroupedExpression()
  else:           left = nil
  
  while precedence < p.peekToken.tokenPrecedence() and p.peekToken.Type != EOF:
    case p.peekToken.Type
    of PLUS, MINUS, ASTERISC, SLASH, LT, GT, LE, GE, EQ, NE:
      p.shiftToken()
      left = p.parseInfixExpression(left)
    of LPAREN:
      left = p.parseCallExpression(left)
    else:
      return left
  
  return left

# 式文の処理
proc parseExpressionStatement(p: Parser): Node =
  let node = p.parseExpression(Lowest)
  return node

# ブロック文の処理
proc parseBlockStatement(p: Parser, endTokenTypes: seq[string]): BlockStatement =
  var bs = BlockStatement(token: p.curToken)
  var endLoop = false
  bs.statements = newSeq[Node]()

  while true:
    for ett in endTokenTypes & EOF:
      if p.peekToken.Type == ett:
        endLoop = true
        break
    if endLoop:
      break
    else:
      p.shiftToken()
      let statement = p.parseStatement()
      if statement != nil:
        bs.statements.add(statement)
        
  return bs

# 文の処理
proc parseStatement(p: Parser): Node =
  case p.curToken.Type
  of LET:    return p.parseLetStatement()
  of DEFINE: return p.parseDefineStatement()
  else:      return p.parseExpressionStatement()

# ASTを作る
proc makeAST*(input: string): seq[Node] =
  var program: seq[Node]
  var lex = newLexer(input)
  var p = lex.newParser()
  var tree = p.parseStatement()
  if tree != nil:
    program.add(tree)
  while p.peekToken.Type != EOF:
    p.shiftToken()
    tree = p.parseStatement()
    if tree != nil:
      program.add(tree)

  return program
