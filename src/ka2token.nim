import tables

type Token* = ref object of RootObj
  Type*: string
  Literal*: string

const
  ILLEGAL*   = "ILLEGAL"
  EOF*       = "EOF"
  # 識別子+リテラル
  IDENT*     = "IDENT"
  INT*       = "INT"
  # 演算子
  ASSIGN*    = "="
  PLUS*      = "+"
  MINUS*    = "-"
  ASTERISC* = "*"
  SLASH*    = "/"
  # 比較演算子
  LT*       = "<"
  GT*       =" >"
  EQ*       = "=="
  PIPE*     = "|>"
  # デリミタ
  COMMA*     = ","
  SEMICOLON* = ";"
  # 括弧
  LPAREN*    = "("
  RPAREN*    = ")"
  # キーワード
  LET*       = "LET"
  DEFINE*    = "DEFINE"
  DO*        = "DO"
  END*       = "END"

let keywords = {
  "let"    : LET,
  "def"    : DEFINE,
  "do"     : DO,
  "end"    : END,
}.newTable

proc LookupIdent*(ident: string): string =
  if keywords.hasKey(ident):
    return keywords[ident]
  return IDENT
