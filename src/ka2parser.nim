import strutils
import ka2token, ka2lexer, ka2node

type Parser = ref object of RootObj
  lexer: Lexer
  curToken: Token
  peekToken: Token
  errors: string

proc newParser(l: Lexer): Parser =
  let p = Parser(lexer: l, curToken: l.nextToken(), peekToken: l.nextToken())
  return p

proc shiftToken(p: Parser) =
  p.curToken = p.peekToken
  p.peekToken = p.lexer.nextToken()

proc parseLetStatement(p: Parser): Node =
  return Node()
  # TODO

proc parseDefineStatement(p: Parser): Node =
  return Node()
  # TODO

proc parseExpression(p: Parser, precedence: Precedence): Node

proc parseInfixExpression(p: Parser, left: Node): Node =
  let operator = p.curToken.Type
  let cp = p.curToken.tokenPrecedence()
  p.shiftToken()
  let right = p.parseExpression(cp)
  let node = Node(
    node_kind:  nkInfixExpression,
    token:      p.curToken,
    operator:   operator,
    left:       left,
    right:      right,
  )
  return node

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

proc parseCallExpression(p: Parser, left: Node): Node =
  var res = Node(
    node_kind: nkCallExpression,
    token:     p.curToken,
    function:  left,
  )
  p.shiftToken()
  res.args = p.parseExpressionList(RPAREN)
  return res
  # TODO

proc parseIdent(p: Parser): Node =
  let node = Node(
    node_kind:  nkIdent,
    token:      p.curToken,
    identValue: p.curToken.Literal,
  )
  return node

proc parseIntLiteral(p: Parser): Node =
  let node = Node(
    node_kind: nkIntLiteral,
    token:     p.curToken,
    intValue:  p.curToken.Literal.parseInt
  )
  return node

proc parseExpression(p: Parser, precedence: Precedence): Node =
  var left: Node
  case p.curToken.Type
  of IDENT:  left = p.parseIdent()
  of INT:    left = p.parseIntLiteral()
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

proc parseExpressionStatement(p: Parser): Node =
    let res = p.parseExpression(Lowest)
    if p.peekToken.Type == SEMICOLON:
      p.shiftToken()
    return res

proc parseStatement(p: Parser): Node =
  case p.curToken.Type
  of "LET":    return p.parseLetStatement()
  of "DEFINE": return p.parseDefineStatement()
  else:        return p.parseExpressionStatement()

proc makeAST*(input: string): Node =
  var lex = newLexer(input)
  let tree = lex.newParser().parseStatement()
  return tree
