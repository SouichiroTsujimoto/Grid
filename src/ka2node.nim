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
  nkArrayType
  nkFunctionType
  nkInfixExpression
  nkGenerator
  nkAssignExpression
  nkLetStatement
  nkMutStatement
  nkDefineStatement
  nkReturnStatement
  nkRetrunExpression
  nkMapFunction
  nkForStatement
  nkExpressionStatement
  nkCallExpression
  nkIfExpression
  nkElseExpression
  nkIfStatement
  nkElifStatement
  nkElseStatement
  nkPipeExpression,
  nkAccessElement,

type Precedence* = enum
  Lowest = 0
  Pipeline
  Assign
  Ifexpression
  Equals
  Lg
  Sum
  Product
  Generator
  Call

proc tokenPrecedence*(tok: Token): Precedence =
  case tok.Type
  of PIPE:            return Pipeline
  of CEQUAL:          return Assign
  of IFEX, COLON:     return Ifexpression
  of LT, GT, LE, GE:  return Lg
  of EE, NE:          return Equals
  of PLUS, MINUS:     return Sum
  of SLASH, ASTERISC: return Product
  of ARROW:           return Generator
  of LPAREN, INDEX:   return Call
  else:               return Lowest

type 
  # ノードクラス
  Node* = ref object of RootObj
    kind*:                        NodeKind
    token*:                       Token
    operator*:                    string
    left*:                        Node
    right*:                       Node
    function*:                    Node
    args*:                        seq[Node]
    intValue*:                    int
    floatValue*:                  float
    identValue*:                  string
    boolValue*:                   bool
    charValue*:                   char
    stringValue*:                 string
    cppCodeValue*:                string
    arrayValue*:                  seq[Node]
    typeValue*:                   string
    let_ident*:                   Node
    let_value*:                   Node
    define_name*:                 Node
    define_ident*:                Node
    define_args*:                 seq[Node]
    define_block*:                BlockStatement
    condition*:                   Node
    consequence*:                 BlockStatement
    consequence_expression*:      Node
    alternative*:                 Node
    generator*:                   Node
    return_expression*:           Node
    index*:                       string
  # ブロック文クラス
  BlockStatement* = ref object of RootObj
    token*: Token
    statements*: seq[Node]