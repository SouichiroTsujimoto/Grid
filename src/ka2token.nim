import tables

type Token* = ref object of RootObj
  Type*: string
  Literal*: string

const
  ILLEGAL*      = "ILLEGAL"
  EOF*          = "EOF"
  # リテラル
  IDENT*        = "IDENT"
  INT*          = "INT"
  FLOAT*        = "FLOAT"
  CHAR*         = "CHAR"
  STRING*       = "STRING"
  # 演算子
  ASSIGN*       = "="
  PLUS*         = "+"
  MINUS*        = "-"
  ASTERISC*     = "*"
  SLASH*        = "/"
  # 比較演算子
  LT*           = "<"
  GT*           = ">"
  LE*           = "<="
  GE*           = ">="
  EQ*           = "=="
  NE*           = "!="
  NOT*          = "!"
  PIPE*         = "|>"
  # デリミタ
  COMMA*        = ","
  COLON*        = ":"
  # 括弧
  LPAREN*       = "("
  RPAREN*       = ")"
  # キーワード
  TRUE*         = "TRUE"
  FALSE*        = "FALSE"
  NIL*          = "NIL"
  LET*          = "LET"
  DEFINE*       = "DEFINE"
  RETURN*       = "RETURN"
  IF*           = "IF"
  ELIF*         = "ELIF"
  ELSE*         = "ELSE"
  DO*           = "DO"
  END*          = "END"
  # 型
  T_INT*        = "T_INT"
  T_FLOAT*      = "T_FLOAT"
  T_CHAR*       = "T_CHAR"
  T_STRING*     = "T_STRING"

let keywords = {
  "True"   : TRUE,
  "False"  : FALSE,
  "Nil"    : NIL,
  "let"    : LET,
  "def"    : DEFINE,
  "return" : RETURN,
  "if"     : IF,
  "elif"   : ELIF,
  "else"   : ELSE,
  "do"     : DO,
  "end"    : END,
  "int"    : T_INT,
  "float"  : T_FLOAT,
  "char"   : T_CHAR,
  "string" : T_STRING,
}.newTable

proc LookupIdent*(ident: string): string =
  if keywords.hasKey(ident):
    return keywords[ident]
  return IDENT
