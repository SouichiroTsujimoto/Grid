import ../src/ka2parser, ../src/ka2cpp
import unittest, strutils

proc findStr(code: string, str: string): bool =
  return code.count(str) != 0

suite "operator":
  test "1 + 1":
    let program = makeAST("1 + 1")
    check(makeCppCode(program[0], 0).findStr("k_add ( 1 ) ( 1 )"))
    initTables()
  test "1 + 1 * 2":
    let program = makeAST("1 + 1 * 2")
    check(makeCppCode(program[0], 0).findStr("k_add ( 1 ) ( k_mul ( 1 ) ( 2 ) )"))
    initTables()
  test "(1 + 1) * 2":
    let program = makeAST("(1 + 1) * 2")
    check(makeCppCode(program[0], 0).findStr("k_mul ( k_add ( 1 ) ( 1 ) ) ( 2 )"))
    initTables()
  test "1 + (1 * 2)":
    let program = makeAST("1 + (1 * 2)")
    check(makeCppCode(program[0], 0).findStr("k_add ( 1 ) ( k_mul ( 1 ) ( 2 ) )"))
    initTables()
  test "\"Hello\" == \"Hello\"":
    let program = makeAST("\"Hello\" == \"Hello\"")
    check(makeCppCode(program[0], 0).findStr("k_eq ( \"Hello\" ) ( \"Hello\" )"))
    initTables()

suite "let":
  test "let #int a = 10":
    let program = makeAST("let #int a = 10")
    check(makeCppCode(program[0], 0).findStr("const int a = 10 ;"))
    initTables()
  test "let #int a = 10 + 10":
    let program = makeAST("let #int a = 10 + 10")
    check(makeCppCode(program[0], 0).findStr("const int a = k_add ( 10 ) ( 10 ) ;"))
    initTables()
  test "let #float a = 1.5":
    let program = makeAST("let #float a = 1.5")
    check(makeCppCode(program[0], 0).findStr("const float a = 1.5 ;"))
    initTables()
  test "let #char a = \'A\'":
    let program = makeAST("let #char a = \'A\'")
    check(makeCppCode(program[0], 0).findStr("const char a = \'A\' ;"))
    initTables()
  test "let #string a = \"Hello\"":
    let program = makeAST("let #string a = \"Hello\"")
    check(makeCppCode(program[0], 0).findStr("const std::string a = \"Hello\" ;"))
    initTables()
  test "let #bool a = True":
    let program = makeAST("let #bool a = True")
    check(makeCppCode(program[0], 0).findStr("const bool a = true ;"))
    initTables()
  test "let #bool a = 1 >= 10":
    let program = makeAST("let #bool a = 1 >= 10")
    check(makeCppCode(program[0], 0).findStr("bool a = k_ge ( 1 ) ( 10 ) ;"))
    initTables()

suite "def":
  test "def #int a(#int b) do return b * 2 end":
    let program = makeAST("def #int a(#int b) do return b * 2 end")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("auto a = [] ( int b ) {"))
    check(res.findStr("return ( k_mul ( b ) ( 2 ) )"))
    check(res.findStr("} ;"))
    initTables()
  test "def #int a(#int b, #int c) do return b / c end":
    let program = makeAST("def #int a(#int b, #int c) do return b / c end")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("auto a = [] ( int b ) {"))
    check(res.findStr("return [b] ( int c ) {"))
    check(res.findStr("return ( k_div ( b ) ( c ) ) ;"))
    check(res.findStr("} ;"))
    check(res.findStr("} ;"))
    initTables()
  test "def #bool a(#int b, #bool c) do let #bool d = b == 10 return c == d end":
    let program = makeAST("def #bool a(#int b, #bool c) do let #bool d = b == 10 return c == d end")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("auto a = [] ( int b ) {"))
    check(res.findStr("return [b] ( bool c ) {"))
    check(res.findStr("bool d = k_eq ( b ) ( 10 ) ;"))
    check(res.findStr("return ( k_eq ( c ) ( d ) ) ;"))
    check(res.findStr("} ;"))
    check(res.findStr("} ;"))
    initTables()

suite "if":
  test "if 5 + 5 == 10 do \"5 + 5 = 10\" else \"?\" end":
    let program = makeAST("if 5 + 5 == 10 do \"5 + 5 = 10\" else \"?\" end")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("( k_eq ( k_add ( 5 ) ( 5 ) ) ( 10 ) ?"))
    check(res.findStr("\"5 + 5 = 10\" :"))
    check(res.findStr("\"?\" ) ;"))
    initTables()
  test "if True do \"1\" elif True do \"2\" else \"3\" end":
    let program = makeAST("if True do \"1\" elif True do \"2\" else \"3\" end")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("( true ?"))
    check(res.findStr("\"1\" :"))
    check(res.findStr("( true ?"))
    check(res.findStr("\"2\" :"))
    check(res.findStr("\"3\" ) ) ;"))
    initTables()
  test "let #int a = if 2 + 2 == 5 do 1984 elif 2 + 2 == 4 do 2020 else 0 end":
    let program = makeAST("let #int a = if 2 + 2 == 5 do 1984 elif 2 + 2 == 4 do 2020 else 0 end")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("const int a = ( k_eq ( k_add ( 2 ) ( 2 ) ) ( 5 ) ?"))
    check(res.findStr("1984 :"))
    check(res.findStr("( k_eq ( k_add ( 2 ) ( 2 ) ) ( 4 ) ?"))
    check(res.findStr("2020 :"))
    check(res.findStr("0 ) ) ;"))
    initTables()

suite "puts":
  test "puts(\"Hello\")":
    let program = makeAST("puts(\"Hello\")")
    check(makeCppCode(program[0], 0).findStr("k_puts ( \"Hello\" ) ;"))
    initTables()