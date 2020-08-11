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
proc parseBlockStatement(p: Parser): BlockStatement

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
  let node = Node(
    kind: nkLetStatement,
    token: p.curToken,
  )
  if p.peekToken.Type != IDENT:
    return Node(kind: nkNil)
  
  p.shiftToken()
  node.let_name = Node(
    kind: nkIdent,
    token: p.curToken,
    identValue: p.curToken.Literal,
  )
  if p.peekToken.Type != ASSIGN:
    return node
  
  p.shiftToken()
  p.shiftToken()
  node.let_value = p.parseExpression(Lowest)
  return node

# 関数定義
# TODO DO-END
proc parseDefineStatement(p: Parser): Node =
  let node = Node(
    kind: nkDefineStatement,
    token: p.curToken,
  )
  if p.peekToken.Type != IDENT:
    return Node(kind: nkNil)

  p.shiftToken()
  node.define_name = Node(
    kind: nkIdent,
    token: p.curToken,
    identValue: p.curToken.Literal
  )
  if p.peekToken.Type != ASSIGN:
    return node
  
  p.shiftToken()
  p.shiftToken()
  node.define_value = p.parseStatement()
  return node

# 中置演算子の処理
proc parseInfixExpression(p: Parser, left: Node): Node =
  let operator = p.curToken.Type
  let cp = p.curToken.tokenPrecedence()
  p.shiftToken()
  let right = p.parseExpression(cp)
  let node = Node(
    kind:  nkInfixExpression,
    token:      p.curToken,
    operator:   operator,
    left:       left,
    right:      right,
  )
  return node

# 引数の処理
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
  
  return list

# 引数の処理
proc parseCallExpression(p: Parser, left: Node): Node =
  var res = Node(
    kind: nkCallExpression,
    token:     p.curToken,
    function:  left,
  )
  p.shiftToken()
  res.args = p.parseExpressionList(RPAREN)
  return res
  # TODO

# 名前
proc parseIdent(p: Parser): Node =
  let node = Node(
    kind: nkIdent,
    token: p.curToken,
    identValue: p.curToken.Literal,
  )
  return node

# 整数リテラル
proc parseIntLiteral(p: Parser): Node =
  let node = Node(
    kind: nkIntLiteral,
    token: p.curToken,
    intValue: p.curToken.Literal.parseInt
  )
  return node

# 真偽値リテラル
proc parseBoolLiteral(p: Parser): Node =
  let node = Node(
    kind: nkBoolLiteral,
    token: p.curToken,
    boolValue: p.curToken.Literal.parseBool
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

# if式
proc parseIfExpression(p: Parser): Node =
  var node = Node(
    kind: nkIfExpression,
    token: p.curToken,
  )
  
  if p.peekToken.Type != LPAREN:
    return Node(kind: nkNil)
  p.shiftToken()
  p.shiftToken()
  node.condition = p.parseExpression(Lowest)
  if p.peekToken.Type != RPAREN:
    return Node(kind: nkNil)
  p.shiftToken()

  if p.peekToken.Type != DO:
    return Node(kind: nkNil)
  p.shiftToken()
  node.consequence = p.parseBlockStatement()

  # elseがあった場合
  if p.peekToken.Type == ELSE:
    node.kind = nkIfAndElseExpression
    p.shiftToken()
    if p.peekToken.Type != DO:
      return Node(kind: nkNil)
    else:
      p.shiftToken()
      node.alternative = p.parseBlockStatement()
      return node
  
  return node

# 式の処理
proc parseExpression(p: Parser, precedence: Precedence): Node =
  var left: Node
  case p.curToken.Type
  of IDENT  : left = p.parseIdent()
  of INT    : left = p.parseIntLiteral()
  of CHAR   : left = p.parseCharLiteral()
  of STRING : left = p.parseStringLiteral()
  of TRUE   : left = p.parseBoolLiteral()
  of FALSE  : left = p.parseBoolLiteral()
  else:      left = nil
  
  while precedence < p.peekToken.tokenPrecedence() and p.peekToken.Type != SEMICOLON:
    case p.peekToken.Type
    of PLUS, MINUS, ASTERISC, SLASH, LT, GT:
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
    if p.peekToken.Type == SEMICOLON:
      p.shiftToken()
    return node

# ブロック文の処理
proc parseBlockStatement(p: Parser): BlockStatement =
  var bs = BlockStatement(token: p.curToken)
  bs.statements = newSeq[Node]()

  p.shiftToken()
  while p.curToken.Type != END and p.curToken.Type != EOF:
    let statement = p.parseStatement()
    if statement != nil:
      bs.statements.add(statement)
    p.shiftToken()
  
  return bs

# 文の処理
proc parseStatement(p: Parser): Node =
  case p.curToken.Type
  of "LET":    return p.parseLetStatement()
  of "DEFINE": return p.parseDefineStatement()
  of "IF":     return p.parseIfExpression()
  else:        return p.parseExpressionStatement()

# ASTを作る
proc makeAST*(input: string): Node =
  var lex = newLexer(input)
  let tree = lex.newParser().parseStatement()
  return tree
