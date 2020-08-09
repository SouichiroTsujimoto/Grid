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
  nkNil
  nkIdent
  nkIntLiteral
  nkPrefixExpression
  nkInfixExpression
  nkLetStatement
  nkDefineStatement
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
  kind*: NodeKind
  token*: Token
  operator*: string
  left*: Node
  right*: Node
  function*: Node
  args*: seq[Node]
  intValue*: int
  identValue*: string
  let_name*: Node
  let_value*: Node
  define_name*: Node
  define_value*: Node
