import ka2token

type NodeKind* = enum
  nkNil
  nkIdent
  nkIntLiteral
  nkFloatLiteral
  nkBoolLiteral
  nkCharLiteral
  nkStringLiteral
  nkPrefixExpression
  nkInfixExpression
  nkLetStatement
  nkDefineStatement
  nkReturnStatement
  nkRetrunExpression
  nkExpressionStatement
  nkCallExpression
  nkIfExpression
  nkIfAndElseExpression

type Precedence* = enum
  Lowest = 0
  Equals
  Lg
  Sum
  Product
  Prefix
  Call

proc tokenPrecedence*(tok: Token): Precedence =
  case tok.Type
  of LPAREN:          return Call
  of SLASH, ASTERISC: return Product
  of PLUS, MINUS:     return Sum
  of LT, GT, LE, GE:  return Lg
  of EQ, NE:          return Equals
  else:               return Lowest

type 
  # ノードクラス
  Node* = ref object of RootObj
    kind*:              NodeKind
    token*:             Token
    operator*:          string
    left*:              Node
    right*:             Node
    function*:          Node
    args*:              seq[Node]
    intValue*:          int
    floatValue*:        float
    identValue*:        string
    boolValue*:         bool
    charValue*:         char
    stringValue*:       string
    let_name*:          Node
    let_value*:         Node
    define_name*:       Node
    define_args*:       seq[Node]
    define_block*:      BlockStatement
    condition*:         Node
    consequence*:       BlockStatement
    alternative*:       BlockStatement
    return_statement*: Node 
    return_expression*: Node
  # ブロック文クラス
  BlockStatement* = ref object of RootObj
    token*: Token
    statements*: seq[Node]