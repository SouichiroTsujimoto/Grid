import ka2token

type Precedence* = enum
  Lowest = 0
  Equals = 1
  Lg
  Sum
  Product
  Prefix
  Call

type NodeKind* = enum
  nkRoot
  nkIdent
  nkIntLiteral
  nkPrefixExpression
  nkInfixExpression
  nkLetStatement
  nkExpressionStatement
  nkFunctionLiteral
  nkCallExpression

proc tokenPrecedence*(tok: Token): Precedence =
  case tok.Type
  of LPAREN: return Call
  of SLASH, ASTERISC: return Product
  of PLUS, MINUS: return Sum
  of LT, GT: return Lg
  of EQ: return Equals
  else: return Lowest

type Node* = ref object of RootObj
  node_kind*: NodeKind
  token*: Token
  operator*: string
  left*: Node
  right*: Node
  function*: Node
  args*: seq[Node]
  intValue*: int
  identValue*: string
