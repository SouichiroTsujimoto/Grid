import ../src/ka2parser, ../src/ka2cpp
import unittest, strutils

proc findStr(code: string, str: string): bool =
  return code.count(str) != 0

suite "operator":
  test "1 + 1":
    let program = makeAST("1 + 1")
    check(makeCppCode(program[0], 0).findStr("k_add ( 1 ) ( 1 )"))
  test "1 + 1 * 2":
    let program = makeAST("1 + 1 * 2")
    check(makeCppCode(program[0], 0).findStr("k_add ( 1 ) ( k_mul ( 1 ) ( 2 ) )"))
  test "(1 + 1) * 2":
    let program = makeAST("(1 + 1) * 2")
    check(makeCppCode(program[0], 0).findStr("k_mul ( k_add ( 1 ) ( 1 ) ) ( 2 )"))
  test "1 + (1 * 2)":
    let program = makeAST("1 + (1 * 2)")
    check(makeCppCode(program[0], 0).findStr("k_add ( 1 ) ( k_mul ( 1 ) ( 2 ) )"))
  test "\"Hello\" == \"Hello\"":
    let program = makeAST("\"Hello\" == \"Hello\"")
    check(makeCppCode(program[0], 0).findStr("k_eq ( \"Hello\" ) ( \"Hello\" )"))
  test "(\'1\' == 1) != True":
    let program = makeAST("(\'1\' == 1) != True")
    check(makeCppCode(program[0], 0).findStr("k_ne ( k_eq ( '1' ) ( 1 ) ) ( true ) "))

suite "let":
  test "let #int a = 10":
    let program = makeAST("let #int a = 10")
    check(makeCppCode(program[0], 0).findStr("const int a = 10 ;"))
  test "let #int a = 10 + 10":
    let program = makeAST("let #int a = 10 + 10")
    check(makeCppCode(program[0], 0).findStr("const int a = k_add ( 10 ) ( 10 ) ;"))
  test "let #float a = 1.5":
    let program = makeAST("let #float a = 1.5")
    check(makeCppCode(program[0], 0).findStr("const float a = 1.5 ;"))
  test "let #char a = \'A\'":
    let program = makeAST("let #char a = \'A\'")
    check(makeCppCode(program[0], 0).findStr("const char a = \'A\' ;"))
  test "let #string a = \"Hello\"":
    let program = makeAST("let #string a = \"Hello\"")
    check(makeCppCode(program[0], 0).findStr("const std::string a = \"Hello\" ;"))
  test "let #bool a = True":
    let program = makeAST("let #bool a = True")
    check(makeCppCode(program[0], 0).findStr("const bool a = true ;"))
  test "let #bool a = 1 >= 10":
    let program = makeAST("let #bool a = 1 >= 10")
    check(makeCppCode(program[0], 0).findStr("bool a = k_ge ( 1 ) ( 10 ) ;"))

suite "def":
  test "def #int a(#int b) do return b * 2 end":
    let program = makeAST("def #int a(#int b) do return b * 2 end")
    check(makeCppCode(program[0], 0).findStr("auto a = [] ( int b ) {"))
    check(makeCppCode(program[0], 0).findStr("return ( k_mul ( b ) ( 2 ) )"))
    check(makeCppCode(program[0], 0).findStr("} ;"))
  test "def #int a(#int b, #int c) do return b / c end":
    let program = makeAST("def #int a(#int b, #int c) do return b / c end")
    check(makeCppCode(program[0], 0).findStr("auto a = [] ( int b ) {"))
    check(makeCppCode(program[0], 0).findStr("return [b] ( int c ) {"))
    check(makeCppCode(program[0], 0).findStr("return ( k_div ( b ) ( c ) ) ;"))
    check(makeCppCode(program[0], 0).findStr("} ;"))
    check(makeCppCode(program[0], 0).findStr("} ;"))
  test "def #bool a(#int b, #bool c) do let #bool d = b == 10 return c == d end":
    let program = makeAST("def #bool a(#int b, #bool c) do let #bool d = b == 10 return c == d end")
    check(makeCppCode(program[0], 0).findStr("auto a = [] ( int b ) {"))
    check(makeCppCode(program[0], 0).findStr("return [b] ( bool c ) {"))
    check(makeCppCode(program[0], 0).findStr("bool d = k_eq ( b ) ( 10 ) ;"))
    check(makeCppCode(program[0], 0).findStr("return ( k_eq ( c ) ( d ) ) ;"))
    check(makeCppCode(program[0], 0).findStr("} ;"))
    check(makeCppCode(program[0], 0).findStr("} ;"))

suite "if":
  test "if 5 + 5 == 10 do \"5 + 5 = 10\" else \"?\" end":
    let program = makeAST("if 5 + 5 == 10 do \"5 + 5 = 10\" else \"?\" end")
    check(makeCppCode(program[0], 0).findStr("( k_eq ( k_add ( 5 ) ( 5 ) ) ( 10 ) ?"))
    check(makeCppCode(program[0], 0).findStr("\"5 + 5 = 10\" :"))
    check(makeCppCode(program[0], 0).findStr("\"?\" ) ;"))
  test "if True do \"1\" elif True do \"2\" else \"3\" end":
    let program = makeAST("if True do \"1\" elif True do \"2\" else \"3\" end")
    check(makeCppCode(program[0], 0).findStr("( true ?"))
    check(makeCppCode(program[0], 0).findStr("\"1\" :"))
    check(makeCppCode(program[0], 0).findStr("( true ?"))
    check(makeCppCode(program[0], 0).findStr("\"2\" :"))
    check(makeCppCode(program[0], 0).findStr("\"3\" ) ) ;"))
  test "let #int a = if 2 + 2 == 5 do 1984 elif 2 + 2 == 4 do 2020 else 0 end":
    let program = makeAST("let #int a = if 2 + 2 == 5 do 1984 elif 2 + 2 == 4 do 2020 else 0 end")
    check(makeCppCode(program[0], 0).findStr("const int a = ( k_eq ( k_add ( 2 ) ( 2 ) ) ( 5 ) ?"))
    check(makeCppCode(program[0], 0).findStr("1984 :"))
    check(makeCppCode(program[0], 0).findStr("( k_eq ( k_add ( 2 ) ( 2 ) ) ( 4 ) ?"))
    check(makeCppCode(program[0], 0).findStr("2020 :"))
    check(makeCppCode(program[0], 0).findStr("0 ) ) ;"))

suite "puts":
  test "puts(\"Hello\")":
    let program = makeAST("puts(\"Hello\")")
    check(makeCppCode(program[0], 0).findStr("k_puts ( \"Hello\" ) ;"))