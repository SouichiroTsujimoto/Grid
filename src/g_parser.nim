import g_token, g_lexer, g_node, g_error
import strutils

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
proc parseType(p: Parser, init: bool): Node
proc parseNameProc(p: Parser, endToken: string): Node
proc parseTypeIdent(p: Parser, left: Node, init: bool): Node

# curTokenとpeekTokenを一つ進める
proc shiftToken(p: Parser) =
  p.curToken = p.peekToken
  p.peekToken = p.lexer.nextToken()

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

proc parseFilePath(p: Parser): Node =
  var node = Node(
    kind:        nkFilePath,
    token:       Token(Type: STRING, Literal: p.curToken.Literal),
    child_nodes: @[],
  )
  
  return node

# TODO import
proc parseImport(p: Parser): Node =
  var node = Node(
    kind:        nkImport,
    token:       p.curToken,
    child_nodes: @[],
  )
  
  p.shiftToken()
  node.child_nodes.add(p.parseFilePath())

  return node

# TODO include
proc parseInclude(p: Parser): Node =
  var node = Node(
    kind:        nkInclude,
    token:       p.curToken,
    child_nodes: @[],
  )
  
  p.shiftToken()
  node.child_nodes.add(p.parseFilePath())

  return node

# コメント
proc parseComment(p: Parser): Node =
  var node = Node(
    kind:        nkComment,
    token:       p.curToken,
    child_nodes: @[],
  )

  p.shiftToken()

  while p.curToken.Type != COMMENTEND:
    if p.curToken.Type == EOF:
      echoErrorMessage("コメントが閉じられませんでした", false, p.curToken.Line)
    else:
      p.shiftToken()

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
    echoErrorMessage("\"end\"が見つかりません", false, p.curToken.Line)

  p.shiftToken()
  return node

# map関数
proc parseMapIdent(p: Parser): Node =
  let node = Node(
    kind:  nkMapIdent,
    token: p.curToken,
  )
  return node

# def文
proc parseDefineStatement(p: Parser): Node =
  var node = Node(
    kind:        nkDefineStatement,
    token:       p.curToken,
    child_nodes: @[],
  )
  p.shiftToken()
  node.child_nodes.add(p.parseType(false))
  if p.peekToken.Type != LPAREN:
    return Node(kind: nkNil)
  p.shiftToken()
  node.child_nodes.add(p.parseNameProc(RPAREN))

  if p.peekToken.Type != DO:
    return Node(kind: nkNil)
  p.shiftToken()

  node.child_nodes.add(p.parseBlockStatement(@[END]))
  if p.peekToken.Type != END:
    echoErrorMessage("\"end\"が見つかりません", false, p.curToken.Line)

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

# TODO 前置演算子
proc parsePrefixOperator(p: Parser): Node =
  var node = Node(
    kind:        nkPrefixOperator,
    token:       p.curToken,
    child_nodes: @[],
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
    if p.peekToken.Type == endToken:
      break
    p.shiftToken()
    args.child_nodes.add(p.parseExpression(Lowest))

  if p.peekToken.Type == endToken:
    p.shiftToken()
    return args
  else:
    echoErrorMessage("要素が多すぎます", false, p.curToken.Line)

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
  args.child_nodes.add(p.parseType(false))

  while p.peekToken.Type == COMMA:
    p.shiftToken()
    if p.peekToken.Type == endToken:
      break
    p.shiftToken()
    args.child_nodes.add(p.parseType(false))
  
  if p.peekToken.Type != endToken:
    echoErrorMessage("\"" & endToken & "\"が見つかりません", false, p.curToken.Line)

  p.shiftToken()
  return args

# 関数呼び出しの処理
proc parseCallExpression(p: Parser, left: Node): Node =
  if left.kind == nkIdent or left.kind == nkPrefixOperator:
    var node = Node(
      kind:  nkCallExpression,
      token: p.curToken,
      child_nodes: @[left, p.parseNodes(RPAREN)],
    )
    return node
  elif left.kind == nkMapIdent:
    var node = Node(
      kind:  nkMapFunction,
      token: p.curToken,
      child_nodes: @[left, p.parseNodes(RPAREN)],
    )
    return node
  else:
    echoErrorMessage("無効な関数呼び出しです", false, p.curToken.Line)

# 複合リテラル
proc parseCompoundLiteral(p: Parser, left: Node): Node =
  var node = Node(
    kind:  nkCompoundLiteral,
    token: p.curToken,
    child_nodes: @[left, p.parseNodes(RBRACE)],
  )
  return node

# 名前
proc parseIdent(p: Parser): Node =
  if p.curToken.Type != IDENT:
    echoErrorMessage("無効な名前です", false, p.curToken.Line)

  var node = Node(
    kind:        nkIdent,
    token:       p.curToken,
    child_nodes: @[],
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

# 負の数のリテラル
proc parseMinusNum(p: Parser): Node =
  var node = Node(
    token: Token(Type: p.peekToken.Type, Literal: "-" & p.peekToken.Literal),
  )
  if p.peekToken.Type == INT:
    node.kind = nkIntLiteral
  elif p.peekToken.Type == FLOAT:
    node.kind = nkFloatLiteral
  else:
    echoErrorMessage("無効な値です", false, p.curToken.Line)
  
  p.shiftToken()
    
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

# nil値
proc parseNilLiteral(p: Parser): Node =
  let node = Node(
    kind:  nkNilLiteral,
    token: p.curToken,
  )
  return node

# int型
proc parseIntType(p: Parser, init: bool): Node =
  var node = Node(
    kind:        nkIntType,
    token:       p.curToken,
    child_nodes: @[],
  )
  if p.peekToken.Type != IDENT:
    echoErrorMessage("変数名がありません", false, p.curToken.Line)
    return node

  p.shiftToken()
  # parseIdent()を使うとTypeIdentになってしまう可能性がある
  node.child_nodes.add(Node(
    kind:        nkIdent,
    token:       p.curToken,
  ))
  
  if init == false:
    return node
  
  if p.peekToken.Type != EQUAL:
    echoErrorMessage("初期化されていません", false, p.curToken.Line)
    return node
  
  p.shiftToken()
  p.shiftToken()
  node.child_nodes.add(p.parseExpression(Lowest))

  return node

# float型
proc parseFloatType(p: Parser, init: bool): Node =
  let node = Node(
    kind:  nkFloatType,
    token: p.curToken,
    child_nodes: @[],
  )
  if p.peekToken.Type != IDENT:
    echoErrorMessage("変数名がありません", false, p.curToken.Line)
    return node

  p.shiftToken()
  node.child_nodes.add(Node(
    kind:        nkIdent,
    token:       p.curToken,
  ))
  
  if init == false:
    return node
  
  if p.peekToken.Type != EQUAL:
    echoErrorMessage("初期化されていません", false, p.curToken.Line)
    return node
  
  p.shiftToken()
  p.shiftToken()
  node.child_nodes.add(p.parseExpression(Lowest))
  
  return node

# char型
proc parseCharType(p: Parser, init: bool): Node =
  let node = Node(
    kind:  nkCharType,
    token: p.curToken,
    child_nodes: @[],
  )
  if p.peekToken.Type != IDENT:
    echoErrorMessage("変数名がありません", false, p.curToken.Line)
    return node

  p.shiftToken()
  node.child_nodes.add(Node(
    kind:        nkIdent,
    token:       p.curToken,
  ))
  
  if init == false:
    return node
  
  if p.peekToken.Type != EQUAL:
    echoErrorMessage("初期化されていません", false, p.curToken.Line)
    return node
  
  p.shiftToken()
  p.shiftToken()
  node.child_nodes.add(p.parseExpression(Lowest))
  
  return node

# string型
proc parseStringType(p: Parser, init: bool): Node =
  let node = Node(
    kind:  nkStringType,
    token: p.curToken,
    child_nodes: @[],
  )
  if p.peekToken.Type != IDENT:
    echoErrorMessage("変数名がありません", false, p.curToken.Line)
    return node

  p.shiftToken()
  node.child_nodes.add(Node(
    kind:        nkIdent,
    token:       p.curToken,
  ))
  
  if init == false:
    return node

  if p.peekToken.Type != EQUAL:
    echoErrorMessage("初期化されていません", false, p.curToken.Line)
    return node
  
  p.shiftToken()
  p.shiftToken()
  node.child_nodes.add(p.parseExpression(Lowest))
  
  return node

# bool型
proc parseBoolType(p: Parser, init: bool): Node =
  let node = Node(
    kind:  nkBoolType,
    token: p.curToken,
    child_nodes: @[],
  )
  if p.peekToken.Type != IDENT:
    echoErrorMessage("変数名がありません", false, p.curToken.Line)
    return node

  p.shiftToken()
  node.child_nodes.add(Node(
    kind:        nkIdent,
    token:       p.curToken,
  ))
  
  if init == false:
    return node
  
  if p.peekToken.Type != EQUAL:
    echoErrorMessage("初期化されていません", false, p.curToken.Line)
    return node
  
  p.shiftToken()
  p.shiftToken()
  node.child_nodes.add(p.parseExpression(Lowest))
  
  return node

# array型
proc parseArrayType(p: Parser, init: bool): Node =
  let node = Node(
    kind:  nkArrayType,
    token: p.curToken,
    child_nodes: @[],
  )

  # array型だけ特殊
  if p.peekToken.Type == IDENT:
    echoErrorMessage("型が間違っています", false, p.curToken.Line)
    return node
  else:
    p.shiftToken()
    let ppa = p.parseType(init)
    node.child_nodes.add(ppa.child_nodes)
    node.token.Type = "T_ARRAY" & "::" & ppa.token.Type
  
  return node

# ユーザー定義型
proc parseTypeIdent(p: Parser, left: Node, init: bool): Node =
  # Token 特殊
  let node = Node(
    kind:  nkTypeIdent,
    token: Token(Type: left.token.Literal, Literal: left.token.Literal, Line: left.token.Line),
    child_nodes: @[],
  )
  if p.curToken.Type != IDENT:
    echoErrorMessage("変数名がありません", false, p.curToken.Line)
    return node

  node.child_nodes.add(Node(
    kind:        nkIdent,
    token:       p.curToken,
  ))
  
  if init == false:
    return node
  
  if p.peekToken.Type != EQUAL:
    echoErrorMessage("初期化されていません", false, p.curToken.Line)
    return node
  
  p.shiftToken()
  p.shiftToken()
  node.child_nodes.add(p.parseExpression(Lowest))
  
  return node

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
    echoErrorMessage("\"end\"がありません", false, p.peekToken.Line)

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
    echoErrorMessage("\':\'が必要です", false, p.peekToken.Line)
  p.shiftToken()
  let cp2 = p.curToken.tokenPrecedence()
  p.shiftToken()
  node.child_nodes.add(p.parseExpression(cp2))
  if p.peekToken.Type != COLON:
    echoErrorMessage("\':\'が必要です", false, p.peekToken.Line)
  p.shiftToken()
  let cp3 = p.curToken.tokenPrecedence()
  p.shiftToken()
  node.child_nodes.add(Node(
    kind: nkElseExpression,
    token: p.curToken,
    child_nodes: @[p.parseExpression(cp3)],
  ))
  return node

# for文
proc parseForStatement(p: Parser): Node =
  var node = Node(
    kind: nkForStatement,
    token: p.curToken,
    child_nodes: @[],
  )
  p.shiftToken()
  var left = p.parseType(false)
  
  if p.peekToken.Type != LARROW:
    echoErrorMessage("\"<-\"が見つかりません", false, p.curToken.Line)
  p.shiftToken()

  node.child_nodes.add(p.parseGenerator(left))
  
  if p.peekToken.Type != DO:
    echoErrorMessage("\"do\"が見つかりません", false, p.curToken.Line)
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
    echoErrorMessage("'('が閉じられていません", false, p.curToken.Line)

# 配列の添字
proc parseAccessElement(p: Parser, left: Node): Node =
  p.shiftToken()
  var node = Node(
    kind:        nkAccessElement,
    token:       p.curToken,
    child_nodes: @[left],
  )
  let index = p.parseExpression(Lowest)
  node.child_nodes.add(index)
  if p.peekToken.Type == RBRACKET:
    p.shiftToken()
    return node
  else:
    echoErrorMessage("'['が閉じられていません", false, p.curToken.Line)

# mut文
proc parseMutStatement(p: Parser): Node =
  var node = Node(
    kind:        nkMutStatement,
    token:       p.curToken,
    child_nodes: @[Node(
      kind:        nkArgs,
      token:       p.curToken,
      child_nodes: @[],
    )],
  )
  p.shiftToken()
  node.child_nodes[0].child_nodes.add(p.parseType(true))

  while p.peekToken.Type == COMMA:
    p.shiftToken()
    if p.peekToken.Type == DO:
      break
    p.shiftToken()
    node.child_nodes[0].child_nodes.add(p.parseType(true))
  
  p.shiftToken()
  
  if p.curToken.Type != DO:
    echoErrorMessage("\"do\"が見つかりません", false, p.curToken.Line)

  node.child_nodes.add(p.parseBlockStatement(@[END]))
  if p.peekToken.Type != END:
    echoErrorMessage("\"end\"が見つかりません", false, p.curToken.Line)
  p.shiftToken()

  return node

# later文
proc parseLaterStatement(p: Parser): Node =
  var node = Node(
    kind:        nkLaterStatement,
    token:       p.curToken,
  )
  p.shiftToken()
  node.child_nodes.add(p.parseType(false))

  while p.peekToken.Type == COMMA:
    p.shiftToken()
    p.shiftToken()
    node.child_nodes.add(p.parseType(false))

  return node

# struct文
proc parseStruct(p: Parser): Node =
  var node = Node(
    kind:        nkStruct,
    token:       p.curToken,
    child_nodes: @[],
  )
  if p.peekToken.Type != IDENT:
    echoErrorMessage("struct名がありません", false, p.curToken.Line)

  p.shiftToken()
  node.child_nodes.add(p.parseIdent())

  if p.peekToken.Type != DO:
    echoErrorMessage("\"DO\"が見つかりません", false, p.curToken.Line)
  p.shiftToken()
  
  node.child_nodes.add(Node(
    kind:        nkArgs,
    token:       p.curToken,
    child_nodes: @[],
  ))

  p.shiftToken()
  node.child_nodes[1].child_nodes.add(p.parseType(false))

  while p.peekToken.Type == COMMA:
    p.shiftToken()
    if p.peekToken.Type == END:
      break
    p.shiftToken()
    node.child_nodes[1].child_nodes.add(p.parseType(false))
  
  if p.peekToken.Type != END:
    echoErrorMessage("\"END\"が見つかりません", false, p.curToken.Line)
  p.shiftToken()

  return node

# $
proc parseDollarExpression(p: Parser): Node =
  var node = Node(
    kind:        nkDollarExpression,
    token:       p.curToken,
    child_nodes: @[],
  )
  let cp = p.curToken.tokenPrecedence()
  p.shiftToken()
  node.child_nodes.add(p.parseExpression(cp))

  return node

proc parseType(p: Parser, init: bool): Node =
  case p.curToken.Type
  of T_INT      : return p.parseIntType(init)
  of T_FLOAT    : return p.parseFloatType(init)
  of T_CHAR     : return p.parseCharType(init)
  of T_STRING   : return p.parseStringType(init)
  of T_BOOL     : return p.parseBoolType(init)
  of T_ARRAY    : return p.parseArrayType(init)
  else:
    var left = p.parseIdent()
    p.shiftToken()
    return p.parseTypeIdent(left, init)

# 式の処理
proc parseExpression(p: Parser, precedence: Precedence): Node =
  var left: Node
  case p.curToken.Type
  of IDENT      : left = p.parseIdent()
  of IFEX       : left = p.parseIfExpression()
  of RETURN     : left = p.parseReturnStatement()
  of MAP        : left = p.parseMapIdent()
  of INT        : left = p.parseIntLiteral()
  of FLOAT      : left = p.parseFloatLiteral()
  of CHAR       : left = p.parseCharLiteral()
  of STRING     : left = p.parseStringLiteral()
  of MINUS      : left = p.parseMinusNum()
  of TRUE       : left = p.parseBoolLiteral()
  of FALSE      : left = p.parseBoolLiteral()
  of NIL        : left = p.parseNilLiteral()
  of LPAREN     : left = p.parseGroupedExpression()
  of LBRACE     : left = p.parseArrayLiteral()
  of DOLLAR     : left = p.parseDollarExpression()
  of PREOP      : left = p.parsePrefixOperator()
  else          : left = p.parseType(true)

  while precedence < p.peekToken.tokenPrecedence() and p.peekToken.Type != EOF:

    case p.peekToken.Type
    of PLUS, MINUS, ASTERISC, SLASH, LT, GT, LTE, GTE, EE, NE, AMPERSAND:
      p.shiftToken()
      left = p.parseInfixExpression(left)
    of EQUAL:
      p.shiftToken()
      left = p.parseAssignExpression(left)
    of LPAREN:
      p.shiftToken()
      left = p.parseCallExpression(left)
    of LBRACE:
      if left.kind == nkIdent:
        p.shiftToken()
        left = p.parseCompoundLiteral(left)
      else:
        return left
    of LBRACKET:
      p.shiftToken()
      left = p.parseAccessElement(left)
    of PIPE:
      p.shiftToken()
      left = p.parsePipeExpression(left)
    of IDENT:
      if left.kind == nkIdent:
        p.shiftToken()
        left = p.parseTypeIdent(left, true)
      else:
        return left
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
  # of LET:    return p.parseLetStatement()
  # of VAR:    return p.parseVarStatement()
  of IMPORT:       return p.parseImport()
  of INCLUDE:      return p.parseInclude()
  of COMMENTBEGIN: return p.parseComment()
  of STRUCT:       return p.parseStruct()
  of MAIN:         return p.parseMainStatement()
  of DEFINE:       return p.parseDefineStatement()
  of FOR:          return p.parseForStatement()
  of IF:           return p.parseIfStatement()
  of MUT:          return p.parseMutStatement()
  of LATER:        return p.parseLaterStatement()
  else:            return p.parseExpressionStatement()

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
