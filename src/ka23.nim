import  ka2parser, ka2cpp, ka2rw
import strutils

var cppCode = """
#include <iostream>
#include <vector>
#include <algorithm>
#include "ka2lib/ka2calc.h"
#include "ka2lib/ka2IO.h"

int main() {
"""

when isMainModule:
  # echo "ファイル名を入力してください"
  # let sourceName = readLine(stdin)
  let sourceName = "main.ka23"
  let input = sourceName.readSource()
  let program = makeAST(input)

  for tree in program:
    cppCode.add(makeCppCode(tree, 0))
  cppCode.add("\n}")

  let cppFileName = sourceName.split(".")[0] & ".cpp"
  writeCpp(cppFileName, cppCode)
#[
  TODO
  ・ if文 ✅
  ・ パイプライン演算子 
  ・ case式
  ・ コメントを実装
  ・ 構文エラーを検出できるようにする 
  ・ エラーメッセージをちゃんと作る
  ・ てきとうすぎる変数名、関数名をどうにかする
  ・ 「仮」「後で修正」「後で変更する」とかいろいろ書いてるところを修正していく
  ・ ka23の関数名がc++の関数と競合しないようにする
]#