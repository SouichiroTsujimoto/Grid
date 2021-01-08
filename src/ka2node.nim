import ka2token

type 
  NodeKind* = enum
    nkRoot
    nkNil
    nkDo
    nkComment
    nkArgs
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
    nkVarStatement
    nkMainStatement
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

  Node* = ref object of RootObj
    kind*:          NodeKind
    token*:         Token
    child_nodes*:   seq[Node]

  Precedence* = enum
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
  of EQUAL:           return Assign
  of IFEX, COLON:     return Ifexpression
  of LT, GT, LE, GE:  return Lg
  of EE, NE:          return Equals
  of PLUS, MINUS:     return Sum
  of SLASH, ASTERISC: return Product
  of ARROW:           return Generator
  of LPAREN, INDEX:   return Call
  else:               return Lowest