import ../src/ka2parser, ../src/ka2cpp
import unittest, strutils

proc findStr(code: string, str: string): bool =
  return code.count(str) != 0

suite "operator":
  test "1 + 1":
    initTables()
    let program = makeAST("1 + 1")
    check(makeCppCode(program[0], 0).findStr("k_add ( 1 ) ( 1 )"))
  test "1 + 1 * 2":
    initTables()
    let program = makeAST("1 + 1 * 2")
    check(makeCppCode(program[0], 0).findStr("k_add ( 1 ) ( k_mul ( 1 ) ( 2 ) )"))
  test "(1 + 1) * 2":
    initTables()
    let program = makeAST("(1 + 1) * 2")
    check(makeCppCode(program[0], 0).findStr("k_mul ( k_add ( 1 ) ( 1 ) ) ( 2 )"))
  test "1 + (1 * 2)":
    initTables()
    let program = makeAST("1 + (1 * 2)")
    check(makeCppCode(program[0], 0).findStr("k_add ( 1 ) ( k_mul ( 1 ) ( 2 ) )"))
  test "\"Hello\" == \"Hello\"":
    initTables()
    let program = makeAST("\"Hello\" == \"Hello\"")
    check(makeCppCode(program[0], 0).findStr("k_eq ( \"Hello\" ) ( \"Hello\" )"))

suite "let":
  test "let #int a = 10":
    initTables()
    let program = makeAST("let #int a = 10")
    check(makeCppCode(program[0], 0).findStr("const int a = 10 ;"))
  test "let #int a = 10 + 10":
    initTables()
    let program = makeAST("let #int a = 10 + 10")
    check(makeCppCode(program[0], 0).findStr("const int a = k_add ( 10 ) ( 10 ) ;"))
  test "let #float a = 1.5":
    initTables()
    let program = makeAST("let #float a = 1.5")
    check(makeCppCode(program[0], 0).findStr("const float a = 1.5 ;"))
  test "let #char a = \'A\'":
    initTables()
    let program = makeAST("let #char a = \'A\'")
    check(makeCppCode(program[0], 0).findStr("const char a = \'A\' ;"))
  test "let #string a = \"Hello\"":
    initTables()
    let program = makeAST("let #string a = \"Hello\"")
    check(makeCppCode(program[0], 0).findStr("const std::string a = \"Hello\" ;"))
  test "let #bool a = True":
    initTables()
    let program = makeAST("let #bool a = True")
    check(makeCppCode(program[0], 0).findStr("const bool a = true ;"))
  test "let #bool a = 1 >= 10":
    initTables()
    let program = makeAST("let #bool a = 1 >= 10")
    check(makeCppCode(program[0], 0).findStr("bool a = k_ge ( 1 ) ( 10 ) ;"))

suite "mut":
  test "mut #int a = 10":
    initTables()
    let program = makeAST("mut #int a = 10")
    check(makeCppCode(program[0], 0).findStr("int a = 10 ;"))
  test "mut #int a = 10 + 10":
    initTables()
    let program = makeAST("mut #int a = 10 + 10")
    check(makeCppCode(program[0], 0).findStr("int a = k_add ( 10 ) ( 10 ) ;"))
  test "mut #float a = 1.5":
    initTables()
    let program = makeAST("mut #float a = 1.5")
    check(makeCppCode(program[0], 0).findStr("float a = 1.5 ;"))
  test "mut #char a = \'A\'":
    initTables()
    let program = makeAST("mut #char a = \'A\'")
    check(makeCppCode(program[0], 0).findStr("char a = \'A\' ;"))
  test "mut #string a = \"Hello\"":
    initTables()
    let program = makeAST("mut #string a = \"Hello\"")
    check(makeCppCode(program[0], 0).findStr("std::string a = \"Hello\" ;"))
  test "mut #bool a = True":
    initTables()
    let program = makeAST("mut #bool a = True")
    check(makeCppCode(program[0], 0).findStr("bool a = true ;"))
  test "mut #bool a = 1 >= 10":
    initTables()
    let program = makeAST("mut #bool a = 1 >= 10")
    check(makeCppCode(program[0], 0).findStr("bool a = k_ge ( 1 ) ( 10 ) ;"))

suite ":=":
  test "mut #int a = 10 a := 20":
    initTables()
    let program = makeAST("mut #int a = 10 a := 20")
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0))
    check(res.findStr("int a = 10 ;"))
    check(res.findStr("a = 20 ;"))
  test "mut #int a = 10 mut #int b = 20 a := b := 20":
    initTables()
    let program = makeAST("mut #int a = 10 mut #int b = 20 a := b := 20")
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0))
    check(res.findStr("int a = 10 ;"))
    check(res.findStr("int b = 20 ;"))
    check(res.findStr("a = b = 20 ;"))

suite "def":
  test "def #int a(#int b) do return b * 2 end":
    initTables()
    let program = makeAST("def #int a(#int b) do return b * 2 end")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("auto a = [] ( int b ) {"))
    check(res.findStr("return ( k_mul ( b ) ( 2 ) )"))
    check(res.findStr("} ;"))
  test "def #int a(#int b, #int c) do return b / c end":
    initTables()
    let program = makeAST("def #int a(#int b, #int c) do return b / c end")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("auto a = [] ( int b ) {"))
    check(res.findStr("return [b] ( int c ) {"))
    check(res.findStr("return ( k_div ( b ) ( c ) ) ;"))
    check(res.findStr("} ;"))
    check(res.findStr("} ;"))
  test "def #bool a(#int b, #bool c) do let #bool d = b == 10 return c == d end":
    initTables()
    let program = makeAST("def #bool a(#int b, #bool c) do let #bool d = b == 10 return c == d end")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("auto a = [] ( int b ) {"))
    check(res.findStr("return [b] ( bool c ) {"))
    check(res.findStr("bool d = k_eq ( b ) ( 10 ) ;"))
    check(res.findStr("return ( k_eq ( c ) ( d ) ) ;"))
    check(res.findStr("} ;"))
    check(res.findStr("} ;"))

suite "if":
  test "if 5 + 5 == 10 do \"5 + 5 = 10\" else \"?\" end":
    initTables()
    let program = makeAST("if 5 + 5 == 10 do \"5 + 5 = 10\" else \"?\" end")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("( k_eq ( k_add ( 5 ) ( 5 ) ) ( 10 ) ?"))
    check(res.findStr("\"5 + 5 = 10\" :"))
    check(res.findStr("\"?\" ) ;"))
  test "if True do \"1\" elif True do \"2\" else \"3\" end":
    initTables()
    let program = makeAST("if True do \"1\" elif True do \"2\" else \"3\" end")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("( true ?"))
    check(res.findStr("\"1\" :"))
    check(res.findStr("( true ?"))
    check(res.findStr("\"2\" :"))
    check(res.findStr("\"3\" ) ) ;"))
  test "let #int a = if 2 + 2 == 5 do 1984 elif 2 + 2 == 4 do 2020 else 0 end":
    initTables()
    let program = makeAST("let #int a = if 2 + 2 == 5 do 1984 elif 2 + 2 == 4 do 2020 else 0 end")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("const int a = ( k_eq ( k_add ( 2 ) ( 2 ) ) ( 5 ) ?"))
    check(res.findStr("1984 :"))
    check(res.findStr("( k_eq ( k_add ( 2 ) ( 2 ) ) ( 4 ) ?"))
    check(res.findStr("2020 :"))
    check(res.findStr("0 ) ) ;"))

suite "puts":
  test "puts(\"Hello\")":
    initTables()
    let program = makeAST("puts(\"Hello\")")
    check(makeCppCode(program[0], 0).findStr("k_puts ( \"Hello\" ) ;"))