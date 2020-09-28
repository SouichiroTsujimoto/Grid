import ../src/ka2parser, ../src/ka2cpp
import unittest, strutils

proc findStr(code: string, str: string): bool =
  return code.count(str) != 0

suite "operator":
  test "1 + 1":
    initTables()
    let program = makeAST("1 + 1")
    check(makeCppCode(program[0], 0).findStr("_k_add ( 1 ) ( 1 )"))
  test "1 + 1 * 2":
    initTables()
    let program = makeAST("1 + 1 * 2")
    check(makeCppCode(program[0], 0).findStr("_k_add ( 1 ) ( _k_mul ( 1 ) ( 2 ) )"))
  test "(1 + 1) * 2":
    initTables()
    let program = makeAST("(1 + 1) * 2")
    check(makeCppCode(program[0], 0).findStr("_k_mul ( _k_add ( 1 ) ( 1 ) ) ( 2 )"))
  test "1 + (1 * 2)":
    initTables()
    let program = makeAST("1 + (1 * 2)")
    check(makeCppCode(program[0], 0).findStr("_k_add ( 1 ) ( _k_mul ( 1 ) ( 2 ) )"))
  test "\"Hello\" == \"Hello\"":
    initTables()
    let program = makeAST("\"Hello\" == \"Hello\"")
    check(makeCppCode(program[0], 0).findStr("_k_ee ( \"Hello\" ) ( \"Hello\" )"))

suite "let":
  test "let #int a = 10":
    initTables()
    let program = makeAST("let #int a = 10")
    check(makeCppCode(program[0], 0).findStr("const int a = 10 ;"))
  test "let #int a = 10 + 10":
    initTables()
    let program = makeAST("let #int a = 10 + 10")
    check(makeCppCode(program[0], 0).findStr("const int a = _k_add ( 10 ) ( 10 ) ;"))
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
    check(makeCppCode(program[0], 0).findStr("bool a = _k_ge ( 1 ) ( 10 ) ;"))

suite "mut":
  test "mut #int a = 10":
    initTables()
    let program = makeAST("mut #int a = 10")
    check(makeCppCode(program[0], 0).findStr("int a = 10 ;"))
  test "mut #int a = 10 + 10":
    initTables()
    let program = makeAST("mut #int a = 10 + 10")
    check(makeCppCode(program[0], 0).findStr("int a = _k_add ( 10 ) ( 10 ) ;"))
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
    check(makeCppCode(program[0], 0).findStr("bool a = _k_ge ( 1 ) ( 10 ) ;"))

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
  test "mut #int a = 10 mut #int b = 20 mut #int c = 30 a := b := c := 20":
    initTables()
    let program = makeAST("mut #int a = 10 mut #int b = 20 mut #int c = 30 a := b := c := 20")
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0))
    check(res.findStr("int a = 10 ;"))
    check(res.findStr("int b = 20 ;"))
    check(res.findStr("int c = 30 ;"))
    check(res.findStr("a = b = c = 20 ;"))

suite "def":
  test "def #int a(#int b) do return b * 2 end":
    initTables()
    let program = makeAST("def #int a(#int b) do return b * 2 end")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("auto a = [] ( int b ) {"))
    check(res.findStr("return ( _k_mul ( b ) ( 2 ) )"))
    check(res.findStr("} ;"))
  test "def #int a(#int b, #int c) do return b / c end":
    initTables()
    let program = makeAST("def #int a(#int b, #int c) do return b / c end")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("auto a = [] ( int b ) {"))
    check(res.findStr("return [b] ( int c ) {"))
    check(res.findStr("return ( _k_div ( b ) ( c ) ) ;"))
    check(res.findStr("} ;"))
    check(res.findStr("} ;"))
  test "def #bool a(#int b, #bool c) do let #bool d = b == 10 return c == d end":
    initTables()
    let program = makeAST("def #bool a(#int b, #bool c) do let #bool d = b == 10 return c == d end")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("auto a = [] ( int b ) {"))
    check(res.findStr("return [b] ( bool c ) {"))
    check(res.findStr("bool d = _k_ee ( b ) ( 10 ) ;"))
    check(res.findStr("return ( _k_ee ( c ) ( d ) ) ;"))
    check(res.findStr("} ;"))
    check(res.findStr("} ;"))

suite "if":
  test "if 5 + 5 == 10 do \"5 + 5 = 10\" else \"?\" end":
    initTables()
    let program = makeAST("if 5 + 5 == 10 do \"5 + 5 = 10\" else \"?\" end")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("( _k_ee ( _k_add ( 5 ) ( 5 ) ) ( 10 ) ?"))
    check(res.findStr("\"5 + 5 = 10\""))
    check(res.findStr(": \"?\" ) ;"))
  test "if True do \"1\" elif True do \"2\" else \"3\" end":
    initTables()
    let program = makeAST("if True do \"1\" elif True do \"2\" else \"3\" end")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("( true ?"))
    check(res.findStr("\"1\""))
    check(res.findStr(": ( true ?"))
    check(res.findStr("\"2\""))
    check(res.findStr(": \"3\" ) ) ;"))
  test "let #int a = if 2 + 2 == 5 do 1984 elif 2 + 2 == 4 do 2020 else 0 end":
    initTables()
    let program = makeAST("let #int a = if 2 + 2 == 5 do 1984 elif 2 + 2 == 4 do 2020 else 0 end")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("const int a = ( _k_ee ( _k_add ( 2 ) ( 2 ) ) ( 5 ) ?"))
    check(res.findStr("1984"))
    check(res.findStr(": ( _k_ee ( _k_add ( 2 ) ( 2 ) ) ( 4 ) ?"))
    check(res.findStr("2020"))
    check(res.findStr(": 0 ) ) ;"))

suite "puts":
  test "puts(\"Hello\")":
    initTables()
    let program = makeAST("puts(\"Hello\")")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("_k_puts ( \"Hello\" ) ;"))
  test "puts(2005)":
    initTables()
    let program = makeAST("puts(2005)")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("_k_puts ( 2005 ) ;"))
  test "puts(True)":
    initTables()
    let program = makeAST("puts(True)")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("_k_puts ( true ) ;"))
  test "puts(\'Q\')":
    initTables()
    let program = makeAST("puts(\'Q\')")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("_k_puts ( \'Q\' ) ;"))
  test "let #char ch = \'Q\' puts(ch)":
    initTables()
    let program = makeAST("let #char ch = \'Q\' puts(ch)")
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0))
    check(res.findStr("const char ch = \'Q\'"))
    check(res.findStr("_k_puts ( ch ) ;"))

suite "array":
  test "let #array #string a = {\"Hello\", \"World\"}":
    initTables()
    let program = makeAST("let #array #string a = {\"Hello\", \"World\"}")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("const std::vector<std::string> a = { \"Hello\" , \"World\" } ;"))
  test "let #array #array #int a = {{1, 2}, {1}}":
    initTables()
    let program = makeAST("let #array #array #int a = {{1, 2}, {1}}")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("const std::vector<std::vector<int>> a = { { 1 , 2 } , { 1 } } ;"))
  test "mut #array #array #int a = {{2, 5, 6}, {4, 5}}":
    initTables()
    let program = makeAST("mut #array #array #int a = {{2, 5, 6}, {4, 5}}")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("std::vector<std::vector<int>> a = { { 2 , 5 , 6 } , { 4 , 5 } } ;"))
  test "mut #array #array #array #int a = {{{2}, {5, 6}}, {{4, 1}, {5}}}":
    initTables()
    let program = makeAST("mut #array #array #array #int a = {{{2}, {5, 6}}, {{4, 1}, {5}}}")
    let res = makeCppCode(program[0], 0)
    check(res.findStr("std::vector<std::vector<std::vector<int>>> a = { { { 2 } , { 5 , 6 } } , { { 4 , 1 } , { 5 } } } ;"))

suite "map":
  test "map({1}, + 1)":
    initTables()
    let program = makeAST("map({1}, + 1)")
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0))
    check(res.findStr("_k_map ( { 1 } , _k_add ( 1 ) ) ;"))
  test "let #array #int b = map({1, 2, 3}, + 1)":
    initTables()
    let program = makeAST("let #array #int b = map({1, 2, 3}, + 1)")
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0))
    check(res.findStr("const std::vector<int> b = _k_map ( { 1 , 2 , 3 } , _k_add ( 1 ) ) ;"))
  test "let #array #int a = {1, 2, 3} let #array #int b = map(a, + 1)":
    initTables()
    let program = makeAST("let #array #int a = {1, 2, 3} let #array #int b = map(a, + 1)")
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0))
    check(res.findStr("const std::vector<int> a = { 1 , 2 , 3 } ;"))
    check(res.findStr("const std::vector<int> b = _k_map ( a , _k_add ( 1 ) ) ;"))
  
suite "for":
  test "for #string a <- {\"a\", \"b\", \"c\"} do puts(a) end":
    initTables()
    let program = makeAST("for #string a <- {\"a\", \"b\", \"c\"} do puts(a) end")
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0))
    check(res.findStr("for ( std::string a : { \"a\" , \"b\" , \"c\" } ) {"))
    check(res.findStr("_k_puts ( a ) ;"))
    check(res.findStr("}"))
  test "for #string a <- {\"a\", \"b\", \"c\"} do for #string b <- {\"a\", \"b\", \"c\"} do for #string c <- {\"a\", \"b\", \"c\"} do puts(c) end end end":
    initTables()
    let program = makeAST("for #string a <- {\"a\", \"b\", \"c\"} do for #string b <- {\"a\", \"b\", \"c\"} do for #string c <- {\"a\", \"b\", \"c\"} do puts(c) end end end")
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0))
    check(res.findStr("for ( std::string a : { \"a\" , \"b\" , \"c\" } ) {"))
    check(res.findStr("for ( std::string b : { \"a\" , \"b\" , \"c\" } ) {"))
    check(res.findStr("for ( std::string c : { \"a\" , \"b\" , \"c\" } ) {"))
    check(res.findStr("_k_puts ( c ) ;"))
    check(res.findStr("}"))
    check(res.findStr("}"))
    check(res.findStr("}"))
  test "mut #int x = 0 for #int a <- {1, 2, 3} do x := x + a end":
    initTables()
    let program = makeAST("mut #int x = 0 for #int a <- {1, 2, 3} do x := x + a end")
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0))
    check(res.findStr("int x = 0 ;"))
    check(res.findStr("for ( int a : { 1 , 2 , 3 } ) {"))
    check(res.findStr("x = _k_add ( x ) ( a ) ;"))
    check(res.findStr("}"))