import ka2token, ka2parser

type Precedence* = enum
  Lowest = 0
  Equals = 1
  Lg
  Sum
  Product
  Prefix
  Call

type NodeKind* = enum
  nkNil
  nkIdent
  nkIntLiteral
  nkBoolLiteral
  nkCharLiteral
  nkStringLiteral
  nkPrefixExpression
  nkInfixExpression
  nkLetStatement
  nkDefineStatement
  nkExpressionStatement
  nkCallExpression
  nkIfExpression
  nkIfAndElseExpression

proc tokenPrecedence*(tok: Token): Precedence =
  case tok.Type
  of LPAREN:          return Call
  of SLASH, ASTERISC: return Product
  of PLUS, MINUS:     return Sum
  of LT, GT:          return Lg
  of EQ:              return Equals
  else:               return Lowest

type 
  # ノードクラス
  Node* = ref object of RootObj
    kind*:         NodeKind
    token*:        Token
    operator*:     string
    left*:         Node
    right*:        Node
    function*:     Node
    args*:         seq[Node]
    intValue*:     int
    identValue*:   string
    boolValue*:    bool
    charValue*:    char
    stringValue*:  string
    let_name*:     Node
    let_value*:    Node
    define_name*:  Node
    define_value*: Node
    condition*:    Node
    consequence*:  BlockStatement
    alternative*:  BlockStatement
  # ブロック文クラス
  BlockStatement* = ref object of RootObj
    token*: Token
    statements*: seq[Node]