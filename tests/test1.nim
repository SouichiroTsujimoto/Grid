import ../src/ka2parser, ../src/ka2cpp, ../src/ka2shaping
import unittest, strutils

proc findStr(code: string, str: string): bool =
  return code.count(str) != 0

suite "operators":
  test "1 + 1":
    initTables()
    let program = "1 + 1".makeAST().astShaping(false, true)[0]
    check(makeCppCode(program[0], 0, true).findStr("( 1 + 1 )"))
  test "1 + -1 * 2":
    initTables()
    let program = "1 + 1 * 2".makeAST().astShaping(false, true)[0]
    check(makeCppCode(program[0], 0, true).findStr("( 1 + ( 1 * 2 ) )"))
  test "(1 + 1) * 2":
    initTables()
    let program = "(1 + 1) * 2".makeAST().astShaping(false, true)[0]
    check(makeCppCode(program[0], 0, true).findStr("( ( 1 + 1 ) * 2 )"))
  test "1 + (1 * 2)":
    initTables()
    let program = "1 + (1 * 2)".makeAST().astShaping(false, true)[0]
    check(makeCppCode(program[0], 0, true).findStr("( 1 + ( 1 * 2 ) )"))
  test "1 + -1 * 2":
    initTables()
    let program = "1 + -1 * 2".makeAST().astShaping(false, true)[0]
    check(makeCppCode(program[0], 0, true).findStr("( 1 + ( -1 * 2 ) )"))
  test "\"Hello\" == \"Hello\"":
    initTables()
    let program = "\"Hello\" == \"Hello\"".makeAST().astShaping(false, true)[0]
    check(makeCppCode(program[0], 0, true).findStr("( \"Hello\" == \"Hello\" )"))

suite "plus":
  test "plus(1, 3)":
    initTables()
    let program = "plus(1, 3)".makeAST().astShaping(false, true)[0]
    check(makeCppCode(program[0], 0, true).findStr("ka23::plus ( 1 , 3 )"))
  
suite "minu":
  test "minu(4, plus(3, 2))":
    initTables()
    let program = "minu(4, plus(3, 2))".makeAST().astShaping(false, true)[0]
    check(makeCppCode(program[0], 0, true).findStr("ka23::minu ( 4 , ka23::plus ( 3 , 2 ) )"))

suite "mult":
  test "mult(minu(100, plus(10, 10)), 2)":
    initTables()
    let program = "mult(minu(100, plus(10, 10)), 2)".makeAST().astShaping(false, true)[0]
    check(makeCppCode(program[0], 0, true).findStr("ka23::mult ( ka23::minu ( 100 , ka23::plus ( 10 , 10 ) ) , 2 )"))

suite "divi":
  test "divi(365, mult(minu(100, plus(10, 10)), 2))":
    initTables()
    let program = "divi(365, mult(minu(100, plus(10, 10)), 2))".makeAST().astShaping(false, true)[0]
    check(makeCppCode(program[0], 0, true).findStr("ka23::divi ( 365 , ka23::mult ( ka23::minu ( 100 , ka23::plus ( 10 , 10 ) ) , 2 ) ) ;"))

suite "|>":
  test "\"Hello\" |> print()":
    initTables()
    let program = "\"Hello\" |> print()".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("ka23::print ( \"Hello\" ) ;"))
  test "1 |> plus(2) |> plus(3) |> divi(6)":
    initTables()
    let program = "1 |> plus(2) |> plus(3) |> divi(6)".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("ka23::divi ( ka23::plus ( ka23::plus ( 1 , 2 ) , 3 ) , 6 ) ;"))
  test "(3 |> plus(10)) + (1 |> plus(1)) |> print()":
    initTables()
    let program = "(3 |> plus(10)) + (1 |> plus(1)) |> print()".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("ka23::print ( ( ka23::plus ( 3 , 10 ) + ka23::plus ( 1 , 1 ) ) ) ;"))

suite "let":
  test "let #int a = 10":
    initTables()
    let program = "let #int a = 10".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("int * a = new int ;"))
    check(res.findStr("* a = 10 ;"))
    check(res.findStr("delete a ;"))
  test "let #int a = 10 + 10":
    initTables()
    let program = "let #int a = 10 + 10".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("int * a = new int ;"))
    check(res.findStr("* a = ( 10 + 10 ) ;"))
    check(res.findStr("delete a ;"))
  test "let #float a = 1.5":
    initTables()
    let program = "let #float a = 1.5".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("float * a = new float ;"))
    check(res.findStr("* a = 1.5f ;"))
    check(res.findStr("delete a ;"))
  test "let #char a = \'A\'":
    initTables()
    let program = "let #char a = \'A\'".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("char * a = new char ;"))
    check(res.findStr("* a = \'A\' ;"))
    check(res.findStr("delete a ;"))


  test "let #string a = \"Hello\"":
    initTables()
    let program = "let #string a = \"Hello\"".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("std::string * a = new std::string ;"))
    check(res.findStr("* a = \"Hello\" ;"))
    check(res.findStr("delete a ;"))
  test "let #bool a = True":
    initTables()
    let program = "let #bool a = True".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("bool * a = new bool ;"))
    check(res.findStr("* a = true ;"))
    check(res.findStr("delete a ;"))
  test "let #bool a = 1 >= 10":
    initTables()
    let program = "let #bool a = 1 >= 10".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("bool * a = new bool ;"))
    check(res.findStr("* a = ( 1 >= 10 ) ;"))
    check(res.findStr("delete a ;"))

suite "var":
  test "var #int a = 10":
    initTables()
    let program = "var #int a = 10".makeAST().astShaping(false, true)[0]
    check(makeCppCode(program[0], 0, true).findStr("int a = 10 ;"))
  test "var #int a = 10 + 10":
    initTables()
    let program = "var #int a = 10 + 10".makeAST().astShaping(false, true)[0]
    check(makeCppCode(program[0], 0, true).findStr("int a = ( 10 + 10 ) ;"))
  test "var #float a = 1.5":
    initTables()
    let program = "var #float a = 1.5".makeAST().astShaping(false, true)[0]
    check(makeCppCode(program[0], 0, true).findStr("float a = 1.5f ;"))
  test "var #char a = \'A\'":
    initTables()
    let program = "var #char a = \'A\'".makeAST().astShaping(false, true)[0]
    check(makeCppCode(program[0], 0, true).findStr("char a = \'A\' ;"))
  test "var #string a = \"Hello\"":
    initTables()
    let program = "var #string a = \"Hello\"".makeAST().astShaping(false, true)[0]
    check(makeCppCode(program[0], 0, true).findStr("std::string a = \"Hello\" ;"))
  test "var #bool a = true":
    initTables()
    let program = "var #bool a = True".makeAST().astShaping(false, true)[0]
    check(makeCppCode(program[0], 0, true).findStr("bool a = true ;"))
  test "var #bool a = 1 >= 10":
    initTables()
    let program = "var #bool a = 1 >= 10".makeAST().astShaping(false, true)[0]
    check(makeCppCode(program[0], 0, true).findStr("bool a = ( 1 >= 10 ) ;"))

suite ":=":
  test "var #int a = 10 a := 20":
    initTables()
    let program = "var #int a = 10 a := 20".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("int a = 10 ;"))
    check(res.findStr("a = 20 ;"))
  test "var #int a = 10 var #int b = 20 a := b := 20":
    initTables()
    let program = "var #int a = 10 var #int b = 20 a := b := 20".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("int a = 10 ;"))
    check(res.findStr("int b = 20 ;"))
    check(res.findStr("a = b = 20 ;"))
  test "var #int a = 10 var #int b = 20 var #int c = 30 a := b := c := 20":
    initTables()
    let program = "var #int a = 10 var #int b = 20 var #int c = 30 a := b := c := 20".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("int a = 10 ;"))
    check(res.findStr("int b = 20 ;"))
    check(res.findStr("int c = 30 ;"))
    check(res.findStr("a = b = c = 20 ;"))

suite "def":
  test "def #int a(#int b) do return b * 2 end":
    initTables()
    let program = "def #int a(#int b) do return b * 2 end".makeAST().astShaping(false, true)[0]
    let res = makeCppCode(program[0], 0, true)
    check(res.findStr("int a ( int b ) {"))
    check(res.findStr("return ( ( b * 2 ) ) ;"))
    check(res.findStr("}"))
  test "def #int a(#int b, #int c) do return b / c end":
    initTables()
    let program = "def #int a(#int b, #int c) do return b / c end".makeAST().astShaping(false, true)[0]
    let res = makeCppCode(program[0], 0, true)
    check(res.findStr("int a ( int b , int c ) {"))
    check(res.findStr("return ( ( b / c ) ) ;"))
    check(res.findStr("}"))
  test "def #bool a(#int b, #bool c) do let #bool d = b == 10 return c == d end":
    initTables()
    let program = "def #bool a(#int b, #bool c) do let #bool d = b == 10 return c == d end".makeAST().astShaping(false, true)[0]
    let res = makeCppCode(program[0], 0, true)
    check(res.findStr("bool a ( int b , bool c ) {"))
    check(res.findStr("const bool d = ( b == 10 ) ;"))
    check(res.findStr("return ( ( c == d ) ) ;"))
    check(res.findStr("}"))

suite "if":
  test "if 1 + 1 <= 3 do print(\"OK\") end":
    initTables()
    let program = "if 1 + 1 <= 3 do print(\"OK\") end".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("if ( ( ( 1 + 1 ) <= 3 ) ) {"))
    check(res.findStr("ka23::print ( \"OK\" ) ;"))
    check(res.findStr("}"))
  test "if 5 + 5 == 10 do print(\"5 + 5 = 10\") else print(\"?\")":
    initTables()
    let program = "if 5 + 5 == 10 do print(\"5 + 5 = 10\") else print(\"?\")".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("if ( ( ( 5 + 5 ) == 10 ) ) {"))
    check(res.findStr("ka23::print ( \"5 + 5 = 10\" ) ;"))
    check(res.findStr("}"))
    check(res.findStr("else {"))
    check(res.findStr("ka23::print ( \"?\" ) ;"))
    check(res.findStr("}"))
  test "if True do return \"1\" elif True do return \"2\" else return \"3\"":
    initTables()
    let program = "if True do return \"1\" elif True do return \"2\" else return \"3\"".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("if ( true ) {"))
    check(res.findStr("return ( \"1\" ) ;"))
    check(res.findStr("}"))
    check(res.findStr("else if ( true ) {"))
    check(res.findStr("return ( \"2\" ) ;"))
    check(res.findStr("}"))
    check(res.findStr("else {"))
    check(res.findStr("return ( \"3\" ) ;"))
    check(res.findStr("}"))
  test "if 1 == 3 do print(\"ok\") elif 4 != 5 do print(True) elif False do print(\"違う\") else print(\"else\") end":
    initTables()
    let program = "if 1 == 3 do print(\"ok\") elif 4 != 5 do print(True) elif False do print(\"違う\") else print(\"else\") end".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("if ( ( 1 == 3 ) ) {"))
    check(res.findStr("ka23::print ( \"ok\" ) ;"))
    check(res.findStr("}"))
    check(res.findStr("else if ( ( 4 != 5 ) ) {"))
    check(res.findStr("ka23::print ( true ) ;"))
    check(res.findStr("}"))
    check(res.findStr("else if ( false ) {"))
    check(res.findStr("ka23::print ( \"違う\" ) ;"))
    check(res.findStr("}"))
    check(res.findStr("else {"))
    check(res.findStr("ka23::print ( \"else\" ) ;"))
    check(res.findStr("}"))

suite "ifex":
  test "ifex 5 + 5 == 10 : \"5 + 5 = 10\" : \"?\"":
    initTables()
    let program = "ifex 5 + 5 == 10 : \"5 + 5 = 10\" : \"?\"".makeAST().astShaping(false, true)[0]
    let res = makeCppCode(program[0], 0, true)
    check(res.findStr("( ( ( 5 + 5 ) == 10 ) ? \"5 + 5 = 10\" : \"?\" ) ;"))
  test "ifex True : \"1\" : ifex True : \"2\" : \"3\"":
    initTables()
    let program = "ifex True : \"1\" : ifex True : \"2\" : \"3\"".makeAST().astShaping(false, true)[0]
    let res = makeCppCode(program[0], 0, true)
    check(res.findStr("( true ? \"1\" : ( true ? \"2\" : \"3\" ) ) ;"))
  test "ifex True : ifex False : \"1\" : \"4\" : ifex True : \"2\" : \"3\"":
    initTables()
    let program = "ifex True : ifex False : \"1\" : \"4\" : ifex True : \"2\" : \"3\"".makeAST().astShaping(false, true)[0]
    let res = makeCppCode(program[0], 0, true)
    check(res.findStr("( true ? ( false ? \"1\" : \"4\" ) : ( true ? \"2\" : \"3\" ) ) ;"))
  test "let #int a = ifex 2 + 2 == 5 : 1984 : ifex 2 + 2 == 4 : 2020 : 0":
    initTables()
    let program = "let #int a = ifex 2 + 2 == 5 : 1984 : ifex 2 + 2 == 4 : 2020 : 0".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("const int a = ( ( ( 2 + 2 ) == 5 ) ? 1984 : ( ( ( 2 + 2 ) == 4 ) ? 2020 : 0 ) ) ;"))

suite "print":
  test "print(\"Hello\")":
    initTables()
    let program = "print(\"Hello\")".makeAST().astShaping(false, true)[0]
    let res = makeCppCode(program[0], 0, true)
    check(res.findStr("ka23::print ( \"Hello\" ) ;"))
  test "print(2005)":
    initTables()
    let program = "print(2005)".makeAST().astShaping(false, true)[0]
    let res = makeCppCode(program[0], 0, true)
    check(res.findStr("ka23::print ( 2005 ) ;"))
  test "print(True)":
    initTables()
    let program = "print(True)".makeAST().astShaping(false, true)[0]
    let res = makeCppCode(program[0], 0, true)
    check(res.findStr("ka23::print ( true ) ;"))
  test "print(\'Q\')":
    initTables()
    let program = "print(\'Q\')".makeAST().astShaping(false, true)[0]
    let res = makeCppCode(program[0], 0, true)
    check(res.findStr("ka23::print ( \'Q\' ) ;"))
  test "let #char ch = \'Q\' print(ch)":
    initTables()
    let program = "let #char ch = \'Q\' print(ch)".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("const char ch = \'Q\'"))
    check(res.findStr("ka23::print ( ch ) ;"))

suite "array":
  test "let #array #string a = {\"Hello\", \"World\"}":
    initTables()
    let program = "let #array #string a = {\"Hello\", \"World\"}".makeAST().astShaping(false, true)[0]
    let res = makeCppCode(program[0], 0, true)
    check(res.findStr("const std::vector<std::string> a = { \"Hello\" , \"World\" } ;"))
  test "let #array #array #int a = {{1, 2}, {1}}":
    initTables()
    let program = "let #array #array #int a = {{1, 2}, {1}}".makeAST().astShaping(false, true)[0]
    let res = makeCppCode(program[0], 0, true)
    check(res.findStr("const std::vector<std::vector<int>> a = { { 1 , 2 } , { 1 } } ;"))
  test "var #array #array #int a = {{2, 5, 6}, {4, 5}}":
    initTables()
    let program = "var #array #array #int a = {{2, 5, 6}, {4, 5}}".makeAST().astShaping(false, true)[0]
    let res = makeCppCode(program[0], 0, true)
    check(res.findStr("std::vector<std::vector<int>> a = { { 2 , 5 , 6 } , { 4 , 5 } } ;"))
  test "var #array #array #array #int a = {{{2}, {5, 6}}, {{4, 1}, {5}}}":
    initTables()
    let program = "var #array #array #array #int a = {{{2}, {5, 6}}, {{4, 1}, {5}}}".makeAST().astShaping(false, true)[0]
    let res = makeCppCode(program[0], 0, true)
    check(res.findStr("std::vector<std::vector<std::vector<int>>> a = { { { 2 } , { 5 , 6 } } , { { 4 , 1 } , { 5 } } } ;"))

suite "[]":
  test "let #array #int a = {1, 2} print(a!!1)":
    initTables()
    let program = "let #array #int a = {1, 2} print(a!!1)".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("std::vector<int> a = { 1 , 2 } ;"))
    check(res.findStr("ka23::print ( a [ 1 ] ) ;"))
  test "let #array #array #int a = {{1, 2}, {3, 4}} print(a!!1!!0)":
    initTables()
    let program = "let #array #array #int a = {{1, 2}, {3, 4}} print(a!!1!!0)".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("const std::vector<std::vector<int>> a = { { 1 , 2 } , { 3 , 4 } } ;"))
    check(res.findStr("ka23::print ( a [ 1 ] [ 0 ] ) ;"))

# 〜保留〜
# suite "map":
#   test "map({1}, + 1)":
#     initTables()
#     let program = "map({1}, + 1)".makeAST().astShaping(false, true)[0]
#     var res = ""
#     for tree in program:
#       res.add(makeCppCode(tree, 0, true))
#     check(res.findStr("ka23::map ( { 1 } , ka23::plus ( 1 ) ) ;"))
#   test "let #array #int b = map({1, 2, 3}, + 1)":
#     initTables()
#     let program = "let #array #int b = map({1, 2, 3}, + 1)".makeAST().astShaping(false, true)[0]
#     var res = ""
#     for tree in program:
#       res.add(makeCppCode(tree, 0, true))
#     check(res.findStr("const std::vector<int> b = ka23::map ( { 1 , 2 , 3 } , ka23::plus ( 1 ) ) ;"))
#   test "let #array #int a = {1, 2, 3} let #array #int b = map(a, + 1)":
#     initTables()
#     let program = "let #array #int a = {1, 2, 3} let #array #int b = map(a, + 1)".makeAST().astShaping(false, true)[0]
#     var res = ""
#     for tree in program:
#       res.add(makeCppCode(tree, 0, true))
#     check(res.findStr("const std::vector<int> a = { 1 , 2 , 3 } ;"))
#     check(res.findStr("const std::vector<int> b = ka23::map ( a , ka23::plus ( 1 ) ) ;"))
  
suite "for":
  test "for #string a <- {\"a\", \"b\", \"c\"} do print(a) end":
    initTables()
    let program = "for #string a <- {\"a\", \"b\", \"c\"} do print(a) end".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("for ( std::string a : { \"a\" , \"b\" , \"c\" } ) {"))
    check(res.findStr("ka23::print ( a ) ;"))
    check(res.findStr("}"))
  test "for #string a <- {\"a\", \"b\", \"c\"} do for #string b <- {\"a\", \"b\", \"c\"} do for #string c <- {\"a\", \"b\", \"c\"} do print(c) end end end":
    initTables()
    let program = "for #string a <- {\"a\", \"b\", \"c\"} do for #string b <- {\"a\", \"b\", \"c\"} do for #string c <- {\"a\", \"b\", \"c\"} do print(c) end end end".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("for ( std::string a : { \"a\" , \"b\" , \"c\" } ) {"))
    check(res.findStr("for ( std::string b : { \"a\" , \"b\" , \"c\" } ) {"))
    check(res.findStr("for ( std::string c : { \"a\" , \"b\" , \"c\" } ) {"))
    check(res.findStr("ka23::print ( c ) ;"))
    check(res.findStr("}"))
    check(res.findStr("}"))
    check(res.findStr("}"))
  test "var #int x = 0 for #int a <- {1, 2, 3} do x := x + a end":
    initTables()
    let program = "var #int x = 0 for #int a <- {1, 2, 3} do x := x + a end".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("int x = 0 ;"))
    check(res.findStr("for ( int a : { 1 , 2 , 3 } ) {"))
    check(res.findStr("x = ( x + a ) ;"))
    check(res.findStr("}"))

suite "len":
  test "var #array #int a = {1, 2} print(len(a))":
    initTables()
    let program = "var #array #int a = {1, 2} print(len(a))".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("std::vector<int> a = { 1 , 2 } ;"))
    check(res.findStr("ka23::print ( ka23::len ( a ) ) ;"))
  test "var #array #int a = {1, 2} a |> len() |> print()":
    initTables()
    let program = "var #array #int a = {1, 2} a |> len() |> print()".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("std::vector<int> a = { 1 , 2 } ;"))
    check(res.findStr("ka23::print ( ka23::len ( a ) ) ;"))

suite "head":
  test "let #array #int x = {1, 2} print(x |> head())":
    initTables()
    let program = "let #array #int x = {1, 2} print(x |> head())".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("const std::vector<int> x = { 1 , 2 } ;"))
    check(res.findStr("ka23::print ( ka23::head ( x ) ) ;"))

suite "tail":
  test "let #array #int x = {1, 2, -3} print((x |> tail()) !! 0)":
    initTables()
    let program = "let #array #int x = {1, 2, -3} print((x |> tail()) !! 0)".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("const std::vector<int> x = { 1 , 2 , -3 } ;"))
    check(res.findStr("ka23::print ( ka23::tail ( x ) [ 0 ] ) ;"))

suite "last":
  test "let #array #int x = {1, 2} print(x |> last())":
    initTables()
    let program = "let #array #int x = {1, 2} print(x |> last())".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("const std::vector<int> x = { 1 , 2 } ;"))
    check(res.findStr("ka23::print ( ka23::last ( x ) ) ;"))

suite "init":
  test "let #array #int x = {1, 2, -3} print((x |> init()) !! 0)":
    initTables()
    let program = "let #array #int x = {1, 2, -3} print((x |> init()) !! 0)".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("const std::vector<int> x = { 1 , 2 , -3 } ;"))
    check(res.findStr("ka23::print ( ka23::init ( x ) [ 0 ] ) ;"))

suite "toString":
  test "let #string a = toString(10)":
    initTables()
    let program = "let #string a = toString(10)".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("const std::string a = ka23::toString ( 10 ) ;"))
  test "let #string a = toString(True)":
    initTables()
    let program = "let #string a = toString(True)".makeAST().astShaping(false, true)[0]
    var res = ""
    for tree in program:
      res.add(makeCppCode(tree, 0, true))
    check(res.findStr("const std::string a = ka23::toString ( true ) ;"))