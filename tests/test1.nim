import ../src/g_parser, ../src/g_cpp, ../src/g_shaping, ../src/g_node, ../src/g_token
import unittest, strutils

proc findStr(code: string, str: string): bool =
  return code.count(str) != 0

proc makeProgram(str: string, inc: bool): string =
  var code = ""
  if inc:
    code = "main do\n" & str & "\nend"
  else:
    code = str & "\n" & "main do\n" & "\nend"

  var nodes = code.makeAST().astShaping(false, true)[0]
  var root = Node(
    kind:        nkRoot,
    token:       Token(Type: "", Literal: ""),
    child_nodes: nodes,
  )
  return makeCppCode(root, 0, true)

suite "operators":
  test "1 + 1":
    initTables()
    let program = "1 + 1".makeProgram(true)
    check(program.findStr("( 1 + 1 )"))
  test "1 + -1 * 2":
    initTables()
    let program = "1 + -1 * 2".makeProgram(true)
    check(program.findStr("( 1 + ( -1 * 2 ) )"))
  test "(1 + 1) * 2":
    initTables()
    let program = "(1 + 1) * 2".makeProgram(true)
    check(program.findStr("( ( 1 + 1 ) * 2 )"))
  test "1 + (1 * 2)":
    initTables()
    let program = "1 + (1 * 2)".makeProgram(true)
    check(program.findStr("( 1 + ( 1 * 2 ) )"))
  test "\"Hello\" == \"Hello\"":
    initTables()
    let program = "\"Hello\" == \"Hello\"".makeProgram(true)
    check(program.findStr("( \"Hello\" == \"Hello\" )"))

suite "plus":
  test "plus(1, 3)":
    initTables()
    let program = "plus(1, 3)".makeProgram(true)
    check(program.findStr("plus ( 1 , 3 )"))
  
suite "minu":
  test "minu(4, plus(3, 2))":
    initTables()
    let program = "minu(1, 3)".makeProgram(true)
    check(program.findStr("minu ( 1 , 3 )"))

suite "mult":
  test "mult(4, plus(3, 2))":
    initTables()
    let program = "mult(1, 3)".makeProgram(true)
    check(program.findStr("mult ( 1 , 3 )"))

suite "divi":
  test "divi(4, plus(3, 2))":
    initTables()
    let program = "divi(1, 3)".makeProgram(true)
    check(program.findStr("divi ( 1 , 3 )"))

suite "|>":
  test "\"Hello\" |> print()":
    initTables()
    let program = "\"Hello\" |> print()".makeProgram(true)
    check(program.findStr("print ( \"Hello\" )"))
  test "1 |> plus(2) |> plus(3) |> divi(6)":
    initTables()
    let program = "1 |> plus(2) |> plus(3) |> divi(6)".makeProgram(true)
    check(program.findStr("grid::divi ( grid::plus ( grid::plus ( 1 , 2 ) , 3 ) , 6 ) ;"))
  test "(3 |> plus(10)) + (1 |> plus(1)) |> toString() |> print()":
    initTables()
    let program = "(3 |> plus(10)) + (1 |> plus(1)) |> toString() |> print()".makeProgram(true)
    check(program.findStr("grid::print ( grid::toString ( ( grid::plus ( 3 , 10 ) + grid::plus ( 1 , 1 ) ) ) ) ;"))

suite "int":
  test "int a = 10":
    initTables()
    let program = "int a = 10".makeProgram(true)
    check(program.findStr("int a = 10 ;"))
  test "int a = 10 + 20 * 30":
    initTables()
    let program = "int a = 10 + 20 * 30".makeProgram(true)
    check(program.findStr("int a = ( 10 + ( 20 * 30 ) ) ;"))
  test "int a = 10 - (10-30)":
    initTables()
    let program = "int a = 10 - (10-30)".makeProgram(true)
    check(program.findStr("int a = ( 10 - ( 10 - 30 ) ) ;"))

suite "float":
  test "float a = 10.2 - 5.2":
    initTables()
    let program = "float a = 10.2 - 5.2".makeProgram(true)
    check(program.findStr("float a = ( 10.2f - 5.2f ) ;"))
  test "float a = 36.5 / 0.5":
    initTables()
    let program = "float a = 36.5 / 0.5".makeProgram(true)
    check(program.findStr("float a = ( 36.5f / 0.5f ) ;"))
  
suite "minus":
  test "float a = -36.5 / -0.5":
    initTables()
    let program = "float a = -36.5 / -0.5".makeProgram(true)
    check(program.findStr("float a = ( -36.5f / -0.5f ) ;"))
  test "int a = -10 - (10--30)":
    initTables()
    let program = "int a = -10 - (10--30)".makeProgram(true)
    check(program.findStr("int a = ( -10 - ( 10 - -30 ) ) ;"))
suite "char":
  test "char a = 'a'":
    initTables()
    let program = "char a = 'a'".makeProgram(true)
    check(program.findStr("char a = 'a' ;"))
  test "char a = '\t'":
    initTables()
    let program = "char a = '\t'".makeProgram(true)
    check(program.findStr("char a = '\t' ;"))

suite "string":
  test "string a = \"Hello\"":
    initTables()
    let program = "string a = \"Hello\"".makeProgram(true)
    check(program.findStr("std::string a = \"Hello\" ;"))
  test "string a = \"hoge\thoge\"":
    initTables()
    let program = "string a = \"hoge\thoge\"".makeProgram(true)
    check(program.findStr("std::string a = \"hoge\thoge\" ;"))
  test "string a = toString(1)":
    initTables()
    let program = "string a = toString(1)".makeProgram(true)
    check(program.findStr("std::string a = grid::toString ( 1 ) ;"))

suite "bool":
  test "bool a = True":
    initTables()
    let program = "bool a = True".makeProgram(true)
    check(program.findStr("bool a = true ;"))
  test "bool a = 1 == 2":
    initTables()
    let program = "bool a = 1 == 2".makeProgram(true)
    check(program.findStr("bool a = ( 1 == 2 ) ;"))

suite "array":
  test "array bool a = {True, False, False}":
    initTables()
    let program = "array bool a = {True, False, False}".makeProgram(true)
    check(program.findStr("std::vector<bool> a = ( std::vector<bool> ) { true , false , false } ;"))
  test "array int a = map({1, 2, 3}, mult(10))":
    initTables()
    let program = "array int a = map({1, 2, 3}, mult(10))".makeProgram(true)
    check(program.findStr("std::vector<int> a = grid::map ( ( std::vector<int> ) { 1 , 2 , 3 } , [] ( int _i ) { return grid::mult ( _i , 10 ) ; } ) ;"))
  test "array string a = {\"Hello\", \"World\"}":
    initTables()
    let program = "array string a = {\"Hello\", \"World\"}".makeProgram(true)
    check(program.findStr("std::vector<std::string> a = ( std::vector<std::string> ) { \"Hello\" , \"World\" } ;"))
  test "array array int a = {{1, 2}, {1}}":
    initTables()
    let program = "array array int a = {{1, 2}, {1}}".makeProgram(true)
    check(program.findStr("std::vector<std::vector<int>> a = ( std::vector<std::vector<int>> ) { ( std::vector<int> ) { 1 , 2 } , ( std::vector<int> ) { 1 } } ;"))
  test "array array int a = {{2, 5, 6}, {4, 5}}":
    initTables()
    let program = "array array int a = {{2, 5, 6}, {4, 5}}".makeProgram(true)
    check(program.findStr("std::vector<std::vector<int>> a = ( std::vector<std::vector<int>> ) { ( std::vector<int> ) { 2 , 5 , 6 } , ( std::vector<int> ) { 4 , 5 } } ;"))
  test "array array array int a = {{{2}, {5, 6}}, {{4, 1}, {5}}}":
    initTables()
    let program = "array array array int a = {{{2}, {5, 6}}, {{4, 1}, {5}}}".makeProgram(true)
    check(program.findStr("std::vector<std::vector<std::vector<int>>> a = ( std::vector<std::vector<std::vector<int>>> ) { ( std::vector<std::vector<int>> ) { ( std::vector<int> ) { 2 } , ( std::vector<int> ) { 5 , 6 } } , ( std::vector<std::vector<int>> ) { ( std::vector<int> ) { 4 , 1 } , ( std::vector<int> ) { 5 } } } ;"))

suite "def":
  test "def int a(int b) do return b * 2 end":
    initTables()
    var program = "def int a(int b) do return b * 2 end".makeProgram(false)
    check(program.findStr("int a ( int b ) {"))
    check(program.findStr("return ( ( b * 2 ) ) ;"))
    check(program.findStr("}"))
  test "def int a(int b, int c) do return b / c end":
    initTables()
    var program = "def int a(int b, int c) do return b / c end".makeProgram(false)
    check(program.findStr("int a ( int b , int c ) {"))
    check(program.findStr("return ( ( b / c ) ) ;"))
    check(program.findStr("}"))
  test "def bool a(int b, bool c) do bool d = b == 10 return c == d end":
    initTables()
    var program = "def bool a(int b, bool c) do bool d = b == 10 return c == d end".makeProgram(false)
    check(program.findStr("bool a ( int b , bool c ) {"))
    check(program.findStr("bool d = ( b == 10 ) ;"))
    check(program.findStr("return ( ( c == d ) ) ;"))
    check(program.findStr("}"))

suite "if":
  test "if 1 + 1 <= 3 do print(\"OK\") end":
    initTables()
    let program = "if 1 + 1 <= 3 do print(\"OK\") end".makeProgram(true)
    check(program.findStr("if ( ( ( 1 + 1 ) <= 3 ) ) {"))
    check(program.findStr("grid::print ( \"OK\" ) ;"))
    check(program.findStr("}"))
  test "if 5 + 5 == 10 do print(\"5 + 5 = 10\") else print(\"?\") end":
    initTables()
    let program = "if 5 + 5 == 10 do print(\"5 + 5 = 10\") else print(\"?\") end".makeProgram(true)
    check(program.findStr("if ( ( ( 5 + 5 ) == 10 ) ) {"))
    check(program.findStr("grid::print ( \"5 + 5 = 10\" ) ;"))
    check(program.findStr("}"))
    check(program.findStr("else {"))
    check(program.findStr("grid::print ( \"?\" ) ;"))
    check(program.findStr("}"))
  test "if True do return \"1\" elif True do return \"2\" else return \"3\" end":
    initTables()
    let program = "if True do return \"1\" elif True do return \"2\" else return \"3\" end".makeProgram(true)
    check(program.findStr("if ( true ) {"))
    check(program.findStr("return ( \"1\" ) ;"))
    check(program.findStr("}"))
    check(program.findStr("else if ( true ) {"))
    check(program.findStr("return ( \"2\" ) ;"))
    check(program.findStr("}"))
    check(program.findStr("else {"))
    check(program.findStr("return ( \"3\" ) ;"))
    check(program.findStr("}"))
  test "if 1 == 3 do print(\"ok\") elif 4 != 5 do print(True) elif False do print(\"違う\") else print(\"else\") end":
    initTables()
    let program = "if 1 == 3 do print(\"ok\") elif 4 != 5 do print(toString(True)) elif False do print(\"違う\") else print(\"else\") end".makeProgram(true)
    check(program.findStr("if ( ( 1 == 3 ) ) {"))
    check(program.findStr("grid::print ( \"ok\" ) ;"))
    check(program.findStr("}"))
    check(program.findStr("else if ( ( 4 != 5 ) ) {"))
    check(program.findStr("grid::print ( grid::toString ( true ) ) ;"))
    check(program.findStr("}"))
    check(program.findStr("else if ( false ) {"))
    check(program.findStr("grid::print ( \"違う\" ) ;"))
    check(program.findStr("}"))
    check(program.findStr("else {"))
    check(program.findStr("grid::print ( \"else\" ) ;"))
    check(program.findStr("}"))

suite "ifex":
  test "ifex 5 + 5 == 10 : \"5 + 5 = 10\" : \"?\"":
    initTables()
    let program = "ifex 5 + 5 == 10 : \"5 + 5 = 10\" : \"?\"".makeProgram(true)
    check(program.findStr("( ( ( 5 + 5 ) == 10 ) ? \"5 + 5 = 10\" : \"?\" ) ;"))
  test "ifex True : \"1\" : ifex True : \"2\" : \"3\"":
    initTables()
    let program = "ifex True : \"1\" : ifex True : \"2\" : \"3\"".makeProgram(true)
    check(program.findStr("( true ? \"1\" : ( true ? \"2\" : \"3\" ) ) ;"))

  test "ifex True : ifex False : \"1\" : \"4\" : ifex True : \"2\" : \"3\"":
    initTables()
    let program = "ifex True : ifex False : \"1\" : \"4\" : ifex True : \"2\" : \"3\"".makeProgram(true)
    check(program.findStr("( true ? ( false ? \"1\" : \"4\" ) : ( true ? \"2\" : \"3\" ) ) ;"))
  test "int a = ifex 2 + 2 == 5 : 1984 : ifex 2 + 2 == 4 : 2020 : 0":
    initTables()
    let program = "int a = ifex 2 + 2 == 5 : 1984 : ifex 2 + 2 == 4 : 2020 : 0".makeProgram(true)
    check(program.findStr("int a = ( ( ( 2 + 2 ) == 5 ) ? 1984 : ( ( ( 2 + 2 ) == 4 ) ? 2020 : 0 ) ) ;"))

suite "print":
  test "print(\"Hello\")":
    initTables()
    let program = "print(\"Hello\")".makeProgram(true)
    check(program.findStr("grid::print ( \"Hello\" ) ;"))
  test "print(toString(2005))":
    initTables()
    let program = "print(toString(2005))".makeProgram(true)
    check(program.findStr("grid::print ( grid::toString ( 2005 ) ) ;"))
  test "char ch = \'Q\' print(toString(ch))":
    initTables()
    let program = "char ch = \'Q\' print(toString(ch))".makeProgram(true)
    check(program.findStr("char ch = \'Q\' ;"))
    check(program.findStr("grid::print ( grid::toString ( ch ) ) ;"))

suite "[]":
  test "array int a = {1, 2} a[1]":
    initTables()
    let program = "array int a = {1, 2} a[1]".makeProgram(true)
    check(program.findStr("std::vector<int> a = ( std::vector<int> ) { 1 , 2 } ;"))
    check(program.findStr("a [ 1 ] ;"))
  test "array array int a = {{1, 2}, {3, 4}} print(toString(a[1][0]))":
    initTables()
    let program = "array array int a = {{1, 2}, {3, 4}} print(toString(a[1][0]))".makeProgram(true)
    check(program.findStr("std::vector<std::vector<int>> a = ( std::vector<std::vector<int>> ) { ( std::vector<int> ) { 1 , 2 } , ( std::vector<int> ) { 3 , 4 } } ;"))
    check(program.findStr("grid::print ( grid::toString ( a [ 1 ] [ 0 ] ) ) ;"))
  
suite "for":
  test "for string a <- {\"a\", \"b\", \"c\"} do print(a) end":
    initTables()
    let program = "for string a <- {\"a\", \"b\", \"c\"} do print(a) end".makeProgram(true)
    check(program.findStr("for ( std::string a : ( std::vector<std::string> ) { \"a\" , \"b\" , \"c\" } ) {"))
    check(program.findStr("grid::print ( a ) ;"))
    check(program.findStr("}"))
  test "for string a <- {\"a\", \"b\", \"c\"} do for string b <- {\"a\", \"b\", \"c\"} do for string c <- {\"a\", \"b\", \"c\"} do print(c) end end end":
    initTables()
    let program = "for string a <- {\"a\", \"b\", \"c\"} do for string b <- {\"a\", \"b\", \"c\"} do for string c <- {\"a\", \"b\", \"c\"} do print(c) end end end".makeProgram(true)
    check(program.findStr("for ( std::string a : ( std::vector<std::string> ) { \"a\" , \"b\" , \"c\" } ) {"))
    check(program.findStr("for ( std::string b : ( std::vector<std::string> ) { \"a\" , \"b\" , \"c\" } ) {"))
    check(program.findStr("for ( std::string c : ( std::vector<std::string> ) { \"a\" , \"b\" , \"c\" } ) {"))
    check(program.findStr("grid::print ( c ) ;"))
    check(program.findStr("}"))
    check(program.findStr("}"))
    check(program.findStr("}"))

suite "len":
  test "array int a = {1, 2} len(a)":
    initTables()
    let program = "array int a = {1, 2} len(a)".makeProgram(true)
    check(program.findStr("std::vector<int> a = ( std::vector<int> ) { 1 , 2 } ;"))
    check(program.findStr("grid::len ( a ) ;"))

  test "array int a = {1, 2} a |> len()":
    initTables()
    let program = "array int a = {1, 2} a |> len()".makeProgram(true)
    check(program.findStr("std::vector<int> a = ( std::vector<int> ) { 1 , 2 } ;"))
    check(program.findStr("grid::len ( a ) ;"))

suite "head":
  test "array int x = {1, 2} print(x |> head() |> toString())":
    initTables()
    let program = "array int x = {1, 2} print(x |> head() |> toString())".makeProgram(true)
    check(program.findStr("std::vector<int> x = ( std::vector<int> ) { 1 , 2 } ;"))
    check(program.findStr("grid::print ( grid::toString ( grid::head ( x ) ) ) ;"))

suite "tail":
  test "array int x = {1, 2, -3} x |> tail()":
    initTables()
    let program = "array int x = {1, 2, -3} x |> tail()".makeProgram(true)
    check(program.findStr("std::vector<int> x = ( std::vector<int> ) { 1 , 2 , -3 } ;"))
    check(program.findStr("grid::tail ( x ) ;"))

suite "last":
  test "array int x = {1, 2} print(x |> last())":
    initTables()
    let program = "array int x = {1, 2} x |> last()".makeProgram(true)
    check(program.findStr("std::vector<int> x = ( std::vector<int> ) { 1 , 2 } ;"))
    check(program.findStr("grid::last ( x ) ;"))

suite "init":
  test "array int x = {1, 2, -3} x |> init()":
    initTables()
    let program = "array int x = {1, 2, -3} x |> init()".makeProgram(true)
    check(program.findStr("std::vector<int> x = ( std::vector<int> ) { 1 , 2 , -3 } ;"))
    check(program.findStr("grid::init ( x ) ;"))

suite "join":
  test "array int x = {1, 2, -3} {1000, 2000} |> join(x)":
    initTables()
    let program = "array int x = {1, 2, -3} {1000, 2000} |> join(x)".makeProgram(true)
    check(program.findStr("std::vector<int> x = ( std::vector<int> ) { 1 , 2 , -3 } ;"))
    check(program.findStr("grid::join ( ( std::vector<int> ) { 1000 , 2000  } , x ) ;"))

suite "toString":
  test "string a = toString(10)":
    initTables()
    let program = "string a = toString(10)".makeProgram(true)
    check(program.findStr("std::string a = grid::toString ( 10 ) ;"))
  test "string a = toString(True)":
    initTables()
    let program = "string a = toString(True)".makeProgram(true)
    check(program.findStr("std::string a = grid::toString ( true ) ;"))

suite "map":
  test "map({1, 2, 3}, plus(1))":
    initTables()
    let program = "map({1, 2, 3}, plus(1))".makeProgram(true)
    check(program.findStr("grid::map ( ( std::vector<int> ) { 1 , 2 , 3 } , [] ( int _i ) { return grid::plus ( _i , 1 ) ; } ) ;"))
  test "array int a = {1, 2, 3} map(a, plus(1))":
    initTables()
    let program = "array int a = {1, 2, 3} map(a, plus(1))".makeProgram(true)
    check(program.findStr("std::vector<int> a = ( std::vector<int> ) { 1 , 2 , 3 } ;"))
    check(program.findStr("grid::map ( a , [] ( int _i ) { return grid::plus ( _i , 1 ) ; } ) ;"))

suite "mut":
  test "mut int a = 10 do a = 20 end":
    initTables()
    let program = "mut int a = 10 do a = 20 end".makeProgram(true)
    check(program.findStr("{"))
    check(program.findStr("int a = 10 ;"))
    check(program.findStr("a = 10 ;"))
    check(program.findStr("}"))

# suite "later":
