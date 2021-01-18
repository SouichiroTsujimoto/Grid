import tables

type Token* = ref object of RootObj
  Type*   : string
  Literal*: string
  Line*   : int

const
  ILLEGAL*      = "ILLEGAL"
  EOF*          = "EOF"
  # リテラル
  IDENT*        = "IDENT"
  INT*          = "INT"
  FLOAT*        = "FLOAT"
  CHAR*         = "CHAR"
  STRING*       = "STRING"
  BOOL*         = "BOOL"
  CPPCODE*      = "CPPCODE"
  ARRAY*        = "ARRAY"
  ELEMENT*      = "ELEMENT"
  VOID*         = "VOID"
  # 演算子
  EQUAL*        = "="
  CEQUAL*       = ":="
  PLUS*         = "+"
  MINUS*        = "-"
  ASTERISC*     = "*"
  SLASH*        = "/"
  LARROW*       = "<-"
  RARROW*       = "->"
  # 比較演算子
  LT*           = "<"
  GT*           = ">"
  LE*           = "<="
  GE*           = ">="
  EE*           = "=="
  NE*           = "!="
  NOT*          = "!"
  PIPE*         = "|>"
  VERTICAL*     = "|"
  # デリミタ
  COMMA*        = ","
  COLON*        = ":"
  SEMICOLON*    = ";"
  # コメント
  COMMENTBEGIN* = "/*"
  COMMENTEND*   = "*/"
  # 括弧
  LPAREN*       = "("
  RPAREN*       = ")"
  LBRACKET*     = "["
  RBRACKET*     = "]"
  LBRACE*       = "{"
  RBRACE*       = "}"
  # キーワード
  TRUE*         = "TRUE"
  FALSE*        = "FALSE"
  NIL*          = "NIL"
  MAIN*         = "MAIN"
  DEFINE*       = "DEFINE"
  RETURN*       = "RETURN"
  IF*           = "IF"
  IFEX*         = "IFEX"
  ELIF*         = "ELIF"
  ELSE*         = "ELSE"
  DO*           = "DO"
  END*          = "END"
  LATER*        = "LATER"
  MUT*          = "MUT"
  IMPORT*       = "IMPORT"
  INCLUDE*      = "INCLUDE"
  STRUCT*       = "STRUCT"
  # 型
  T_INT*        = "T_INT"
  T_FLOAT*      = "T_FLOAT"
  T_CHAR*       = "T_CHAR"
  T_STRING*     = "T_STRING"
  T_BOOL*       = "T_BOOL"
  T_ARRAY*      = "T_ARRAY"
  T_FUNCTION*   = "T_FUNCTION"
  # その他
  MAP*          = "MAP"
  FOR*          = "FOR"
  AUTO*         = "AUTO"
  FUNCTION*     = "FUNCTION"
  OTHER*        = "OTHER"

let keywords = {
  "True"      : TRUE,
  "False"     : FALSE,
  "Nil"       : NIL,
  "main"      : MAIN,
  "def"       : DEFINE,
  "return"    : RETURN,
  "if"        : IF,
  "ifex"      : IFEX,
  "elif"      : ELIF,
  "else"      : ELSE,
  "do"        : DO,
  "end"       : END,
  "map"       : MAP,
  "for"       : FOR,
  "mut"       : MUT,
  "later"     : LATER,
  "import"    : IMPORT,
  "include"   : INCLUDE,
  "struct"    : STRUCT,
  "int"       : T_INT,
  "float"     : T_FLOAT,
  "char"      : T_CHAR,
  "string"    : T_STRING,
  "bool"      : T_BOOL,
  "array"     : T_ARRAY,
  "function"  : T_FUNCTION,
}.newTable

proc LookupIdent*(ident: string): string =
  if keywords.hasKey(ident):
    return keywords[ident]
  return IDENT
