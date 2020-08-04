import strutils
import ka2lexer, ka2parser, ka2cpp

#[
  TODO ファイル読み込み、ファイル書き出しができるようにする
  TODO puts関数を実装する
  TODO 変数を実装
]#

var cpp_code = """
#include <iostream>
#include "ka2calc.h"

int main() {
"""

when isMainModule:
  var cpp_code_parts = makeCppCodeParts("0", "(3 + 2) * 4".lexer.parser)

  cpp_code.add("  int expr = " & cpp_code_parts & ";\n")
  cpp_code.add("  std::cout << expr << std::endl;\n")
  cpp_code.add("}")

  echo cpp_code
