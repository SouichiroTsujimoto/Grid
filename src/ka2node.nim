import ka2token

type NodeKind* = enum
  nkNil
  nkIdent
  nkNilLiteral
  nkIntLiteral
  nkFloatLiteral
  nkBoolLiteral
  nkCharLiteral
  nkStringLiteral
  nkCppCode
  nkArrayLiteral
  nkIntType
  nkFloatType
  nkBoolType
  nkCharType
  nkStringType
  nkFunctionType
  nkInfixExpression
  nkAssignExpression
  nkLetStatement
  nkMutStatement
  nkDefineStatement
  nkReturnStatement
  nkRetrunExpression
  nkExpressionStatement
  nkCallExpression
  nkIfExpression
  nkElifExpression 
  nkElseExpression

type Precedence* = enum
  Lowest = 0
  Equals
  Lg
  Sum
  Product
  Assign
  Call

proc tokenPrecedence*(tok: Token): Precedence =
  case tok.Type
  of LPAREN:          return Call
  of CEQUAL:          return Assign
  of SLASH, ASTERISC: return Product
  of PLUS, MINUS:     return Sum
  of LT, GT, LE, GE:  return Lg
  of EE, NE:          return Equals
  else:               return Lowest

type 
  # ノードクラス
  Node* = ref object of RootObj
    kind*:                NodeKind
    token*:               Token
    operator*:            string
    left*:                Node
    right*:               Node
    function*:            Node
    args*:                seq[Node]
    intValue*:            int
    floatValue*:          float
    identValue*:          string
    boolValue*:           bool
    charValue*:           char
    stringValue*:         string
    cppCodeValue*:        string
    arrayValue*:          seq[Node]
    typeValue*:           string
    let_ident*:           Node
    let_value*:           Node
    define_name*:         Node
    define_ident*:        Node
    define_args*:         seq[Node]
    define_block*:        BlockStatement
    condition*:           Node
    consequence*:         BlockStatement
    alternative*:         Node
    return_expression*:   Node
  # ブロック文クラス
  BlockStatement* = ref object of RootObj
    token*: Token
    statements*: seq[Node]