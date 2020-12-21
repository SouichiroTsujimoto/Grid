import strutils
import ka2token, ka2lexer, ka2node, ka2error

# パーサクラス
type Parser = ref object of RootObj
  lexer: Lexer
  curToken: Token
  peekToken: Token
  errors: string

# パーサクラスのインスタンスを作る
proc newParser(l: Lexer): Parser =
  let p = Parser(
    lexer: l,
    curToken: l.nextToken(),
    peekToken: l.nextToken(),
  )
  return p

proc parseExpression(p: Parser, precedence: Precedence): Node
proc parseStatement(p: Parser): Node
proc parseBlockStatement(p: Parser, endTokenTypes: seq[string]): Node
proc parseCallExpression(p: Parser, left: Node): Node
proc parseNodes(p: Parser, endToken: string): Node
proc parseType(p: Parser): Node
proc parseNameProc(p: Parser, endToken: string): Node

# curTokenとpeekTokenを一つ進める
proc shiftToken(p: Parser) =
  p.curToken = p.peekToken
  p.peekToken = p.lexer.nextToken()

# let文
proc parseLetStatement(p: Parser): Node =
  var node = Node(
    kind:        nkLetStatement,
    token:       p.curToken,
    child_nodes: @[],
  )
  p.shiftToken()
  node.child_nodes.add(p.parseType())

  if p.peekToken.Type != EQUAL:
    echoErrorMessage("初期化されていません", false)
    return node
  
  p.shiftToken()
  p.shiftToken()
  node.child_nodes.add(p.parseExpression(Lowest))

  return node

# var文
proc parseVarStatement(p: Parser): Node =
  var node = Node(
    kind:        nkVarStatement,
    token:       p.curToken,
    child_nodes: @[],
  )
  p.shiftToken()
  node.child_nodes.add(p.parseType())

  if p.peekToken.Type != EQUAL:
    return node
  
  p.shiftToken()
  p.shiftToken()
  node.child_nodes.add(p.parseExpression(Lowest))

  return node

# return文
proc parseReturnStatement(p: Parser): Node =
  var node = Node(
    kind:        nkReturnStatement,
    token:       p.curToken,
    child_nodes: @[],
  )
  p.shiftToken()
  node.child_nodes.add(p.parseExpression(Lowest))
  return node

# main文
proc parseMainStatement(p: Parser): Node =
  var node = Node(
    kind:        nkMainStatement,
    token:       p.curToken,
    child_nodes: @[],
  )

  if p.peekToken.Type != DO:
    return Node(kind: nkNil)
  p.shiftToken()

  node.child_nodes.add(p.parseBlockStatement(@[END]))
  if p.peekToken.Type != END:
    return Node(kind: nkNil)

  p.shiftToken()
  return node

# map関数
proc parseMapFunction(p: Parser): Node =
  var node = Node(
    kind:  nkMapFunction,
    token: p.curToken,
    child_nodes: @[],
  )
  p.shiftToken()
  node.child_nodes.add(p.parseNodes(RPAREN))
  if p.curToken.Type != RPAREN:
    return Node(kind: nkNil)

  return node

# def文
proc parseDefineStatement(p: Parser): Node =
  var node = Node(
    kind:        nkDefineStatement,
    token:       p.curToken,
    child_nodes: @[],
  )
  p.shiftToken()
  node.child_nodes.add(p.parseType())
  if p.peekToken.Type != LPAREN:
    return Node(kind: nkNil)
  p.shiftToken()
  node.child_nodes.add(p.parseNameProc(RPAREN))

  if p.peekToken.Type != DO:
    return Node(kind: nkNil)
  p.shiftToken()

  node.child_nodes.add(p.parseBlockStatement(@[END]))
  if p.peekToken.Type != END:
    return Node(kind: nkNil)

  p.shiftToken()
  return node

# 中置演算子の処理
proc parseInfixExpression(p: Parser, left: Node): Node =
  let operator = p.curToken
  let cp = operator.tokenPrecedence()
  p.shiftToken()
  let right = p.parseExpression(cp)
  let node = Node(
    kind:        nkInfixExpression,
    token:       operator,
    child_nodes: @[left, right],
  )
  return node

# Generator
proc parseGenerator(p: Parser, left: Node): Node =
  let operator = p.curToken
  let cp = operator.tokenPrecedence()
  p.shiftToken()
  let right = p.parseExpression(cp)
  let node = Node(
    kind:        nkGenerator,
    token:       operator,
    child_nodes: @[left, right],
  )
  return node

# パイプライン演算子
proc parsePipeExpression(p: Parser, left: Node): Node =
  let operator = p.curToken
  let cp = operator.tokenPrecedence()
  p.shiftToken()
  let right = p.parseExpression(cp)
  let node = Node(
    kind:        nkPipeExpression,
    token:       operator,
    child_nodes: @[left, right],
  )
  return node

# 配列の要素へのアクセス
proc parseAccessElement(p: Parser, left: Node): Node =
  let operator = p.curToken
  let cp = operator.tokenPrecedence()
  p.shiftToken()
  let right = p.parseExpression(cp)
  let node = Node(
    kind:        nkAccessElement,
    token:       operator,
    child_nodes: @[left, right],
  )
  return node

# 代入式
proc parseAssignExpression(p: Parser, left: Node): Node =
  let operator = p.curToken
  let cp = operator.tokenPrecedence()
  p.shiftToken()
  let right = p.parseExpression(cp)
  let node = Node(
    kind:        nkAssignExpression,
    token:       operator,
    child_nodes: @[left, right],
  )
  return node

# 引数の処理など
proc parseNodes(p: Parser, endToken: string): Node =
  var args = Node(
    kind:        nkArgs,
    token:       p.curToken,
    child_nodes: @[],
  )
  if p.peekToken.Type == endToken:
    p.shiftToken()
    return args


  p.shiftToken()
  args.child_nodes.add(p.parseExpression(Lowest))
  while p.peekToken.Type == COMMA:
    p.shiftToken()
    p.shiftToken()
    args.child_nodes.add(p.parseExpression(Lowest))
  
  # echo "---------"
  # echo p.curToken.Type
  # echo p.peekToken.Type
  # echo endToken
  # echo "---------"

  if p.peekToken.Type == endToken:
    p.shiftToken()
    return args
  else:
    echo "構文エラー！！！(0)"

# 関数を宣言するときの引数の処理
proc parseNameProc(p: Parser, endToken: string): Node =
  var args = Node(
    kind: nkArgs,
    token: p.curToken,
    child_nodes: @[],
  )
  if p.peekToken.Type == endToken:
    p.shiftToken()
    return args

  p.shiftToken()
  args.child_nodes.add(p.parseType())

  while p.peekToken.Type == COMMA:
    p.shiftToken()
    p.shiftToken()
    args.child_nodes.add(p.parseType())

  p.shiftToken()
  return args

# 関数呼び出しの処理
proc parseCallExpression(p: Parser, left: Node): Node =
  var node = Node(
    kind:  nkCallExpression,
    token: p.curToken,
    child_nodes: @[left, p.parseNodes(RPAREN)],
  )
  return node

# 名前
proc parseIdent(p: Parser): Node =
  let node = Node(
    kind:  nkIdent,
    token: p.curToken,
  )
  return node


# 整数値リテラル
proc parseIntLiteral(p: Parser): Node =
  let node = Node(
    kind:  nkIntLiteral,
    token: p.curToken,
  )
  return node

# 小数値リテラル
proc parseFloatLiteral(p: Parser): Node =
  let node = Node(
    kind:  nkFloatLiteral,
    token: p.curToken,
  )
  return node

# 文字リテラル
proc parseCharLiteral(p: Parser): Node =
  let node = Node(
    kind:  nkCharLiteral,
    token: p.curToken,
  )
  return node

# 文字列リテラル
proc parseStringLiteral(p: Parser): Node =
  let node = Node(
    kind:  nkStringLiteral,
    token: p.curToken,
  )
  return node

# 真偽値リテラル
proc parseBoolLiteral(p: Parser): Node =
  let node = Node(
    kind:  nkBoolLiteral,
    token: p.curToken,
  )
  return node

# 配列
proc parseArrayLiteral(p: Parser): Node =
  var node = Node(
    kind:  nkArrayLiteral,
    token: p.curToken,
    child_nodes: @[p.parseNodes(RBRACE)]
  )
  if p.curToken.Type == RBRACE:
    return node
  else:
    return nil

# 埋め込みC++コード 【保留】
# proc parseCppCode(p: Parser): Node =
#   let node = Node(
#     kind: nkCppCode,
#     token: p.curToken,
#     cppCodeValue: p.curToken.Literal,
#   )
#   return node

# nil値
proc parseNilLiteral(p: Parser): Node =
  let node = Node(
    kind:  nkNilLiteral,
    token: p.curToken,
  )
  return node

# int型
proc parseIntType(p: Parser): Node =
  var node = Node(
    kind:  nkIntType,
    token: p.curToken,
  )
  if p.peekToken.Type == IDENT:
    p.shiftToken()
    node.child_nodes.add(p.parseIdent())
  return node

# float型
proc parseFloatType(p: Parser): Node =
  let node = Node(
    kind:  nkFloatType,
    token: p.curToken,
  )
  if p.peekToken.Type == IDENT:
    p.shiftToken()
    node.child_nodes.add(p.parseIdent())
  return node

# char型
proc parseCharType(p: Parser): Node =
  let node = Node(
    kind:  nkCharType,
    token: p.curToken,
  )
  if p.peekToken.Type == IDENT:
    p.shiftToken()
    node.child_nodes.add(p.parseIdent())
  return node

# string型
proc parseStringType(p: Parser): Node =
  let node = Node(
    kind:  nkStringType,
    token: p.curToken,
  )
  if p.peekToken.Type == IDENT:
    p.shiftToken()
    node.child_nodes.add(p.parseIdent())
  return node

# bool型
proc parseBoolType(p: Parser): Node =
  let node = Node(
    kind:  nkBoolType,
    token: p.curToken,
  )
  if p.peekToken.Type == IDENT:
    p.shiftToken()
    node.child_nodes.add(p.parseIdent())
  return node

# array型
proc parseArrayType(p: Parser): Node =
  let node = Node(
    kind:  nkArrayType,
    token: p.curToken,
  )
  if p.peekToken.Type == IDENT:
    p.shiftToken()
    node.child_nodes.add(p.parseIdent())
  else:
    p.shiftToken()
    let ppa = p.parseType()
    node.child_nodes.add(ppa.child_nodes)
    node.token.Type = "T_ARRAY" & "::" & ppa.token.Type
  return node

# function型
proc parseFunctionType(p: Parser): Node =
  let node = Node(
    kind:  nkFunctionType,
    token: p.curToken,
  )
  if p.peekToken.Type == IDENT:
    p.shiftToken()
    node.child_nodes.add(p.parseIdent())
  return node

#------ここまで------

# if文
proc parseIfStatement(p: Parser): Node =
  var node = Node(
    kind:        nkIfStatement,
    token:       p.curToken,
    child_nodes: @[],
  )
  p.shiftToken()
  node.child_nodes.add(p.parseExpression(Lowest))
  if p.peekToken.Type != DO:
    return Node(kind: nkNil)
  p.shiftToken()
  node.child_nodes.add(p.parseBlockStatement(@[ELIF, ELSE, END]))
  # elifがあった場合
  if p.peekToken.Type == ELIF:
    p.shiftToken()
    let res = p.parseIfStatement()
    node.child_nodes.add(Node(
      kind:        nkElifStatement,
      token:       res.token,
      child_nodes: res.child_nodes,
    ))
    return node
  # elseがあった場合
  elif p.peekToken.Type == ELSE:
    p.shiftToken()
    node.child_nodes.add(Node(
      kind:        nkElseStatement,
      token:       p.curToken,
      child_nodes: @[p.parseBlockStatement(@[END])],
    ))
    p.shiftToken()
    return node
  elif p.peekToken.Type == END:
    p.shiftToken()
    return node
  else:
    echo "構文エラー！！！(0.0.1)"
    quit()

# if式
proc parseIfExpression(p: Parser): Node =
  var node = Node(
    kind:        nkIfExpression,
    token:       p.curToken,
    child_nodes: @[],
  )
  let cp1 = p.curToken.tokenPrecedence()
  p.shiftToken()
  node.child_nodes.add(p.parseExpression(cp1))
  if p.peekToken.Type != COLON:
    echo "構文エラー！！！(0.1)"
    quit()
  p.shiftToken()
  let cp2 = p.curToken.tokenPrecedence()
  p.shiftToken()
  node.child_nodes.add(p.parseExpression(cp2))
  if p.peekToken.Type == COLON:
    p.shiftToken()
    let cp3 = p.curToken.tokenPrecedence()
    p.shiftToken()
    node.child_nodes.add(Node(
      kind: nkElseExpression,
      token: p.curToken,
      child_nodes: @[p.parseExpression(cp3)],
    ))
    return node
  else:
    echo "構文エラー！！！(1)"
    quit()

# for文
proc parseForStatement(p: Parser): Node =
  var node = Node(
    kind: nkForStatement,
    token: p.curToken,
    child_nodes: @[],
  )
  p.shiftToken()
  node.child_nodes.add(p.parseExpression(Lowest))
  if p.peekToken.Type != DO:
    return Node(kind: nkNil)
  p.shiftToken()
  node.child_nodes.add(p.parseBlockStatement(@[END]))
  p.shiftToken()
  return node

# 括弧
proc parseGroupedExpression(p: Parser): Node =
  p.shiftToken()
  let node = p.parseExpression(Lowest)
  if p.peekToken.Type == RPAREN:
    p.shiftToken()
    return node
  else:
    return nil

proc parseType(p: Parser): Node =
  case p.curToken.Type
  of T_INT      : return p.parseIntType()
  of T_FLOAT    : return p.parseFloatType()
  of T_CHAR     : return p.parseCharType()
  of T_STRING   : return p.parseStringType()
  of T_BOOL     : return p.parseBoolType()
  of T_ARRAY    : return p.parseArrayType()
  of T_FUNCTION : return p.parseFunctionType()
  else          : echoErrorMessage("存在しない型です", false)

# 式の処理
proc parseExpression(p: Parser, precedence: Precedence): Node =
  var left: Node
  case p.curToken.Type
  of IFEX       : left = p.parseIfExpression()
  of RETURN     : left = p.parseReturnStatement()
  of IDENT      : left = p.parseIdent()
  of MAP        : left = p.parseMapFunction()
  of INT        : left = p.parseIntLiteral()
  of FLOAT      : left = p.parseFloatLiteral()
  of CHAR       : left = p.parseCharLiteral()
  of STRING     : left = p.parseStringLiteral()
  # of CPPCODE    : left = p.parseCppCode()
  of TRUE       : left = p.parseBoolLiteral()
  of FALSE      : left = p.parseBoolLiteral()
  of NIL        : left = p.parseNilLiteral()
  of LPAREN     : left = p.parseGroupedExpression()
  of LBRACE     : left = p.parseArrayLiteral()
  else          : left = p.parseType()

  while precedence < p.peekToken.tokenPrecedence() and p.peekToken.Type != EOF or left == nil:
    if left != nil:
      p.shiftToken()
    case p.curToken.Type
    of PLUS, MINUS, ASTERISC, SLASH, LT, GT, LE, GE, EE, NE:
      left = p.parseInfixExpression(left)
    of ARROW:
      left = p.parseGenerator(left)
    of CEQUAL:
      left = p.parseAssignExpression(left)
    of LPAREN:
      left = p.parseCallExpression(left)
    of PIPE:
      left = p.parsePipeExpression(left)
    of INDEX:
      left = p.parseAccessElement(left)
    else:
      return left
  
  return left

# 式文
proc parseExpressionStatement(p: Parser): Node =
  let node = p.parseExpression(Lowest)
  return node

# ブロック文の処理
proc parseBlockStatement(p: Parser, endTokenTypes: seq[string]): Node =
  var bs = Node(
    kind:        nkDo,
    token:       p.curToken,
    child_nodes: @[],
  )
  var endLoop = false

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
        bs.child_nodes.add(statement)
  return bs

# 文の処理
proc parseStatement(p: Parser): Node =
  case p.curToken.Type
  of LET:    return p.parseLetStatement()
  of VAR:    return p.parseVarStatement()
  of MAIN:   return p.parseMainStatement()
  of MAP:    return p.parseMapFunction()
  of DEFINE: return p.parseDefineStatement()
  of FOR:    return p.parseForStatement()
  of IF:     return p.parseIfStatement()
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
