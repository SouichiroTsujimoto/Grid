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
  ・ パイプライン演算子 ✅
  ・ 【急遽】 負の数実装 ✅
  ・ plus, minus, multiply, divide関数を作る
  ・ 関数を増やす
    ・ ~配列~
      ・ 要素へのアクセス (hoge[0]<- これ) ✅
      ・ add関数 ✅
      ・ len関数 ✅
    ・ ~変数~
      ・ 型のキャスト
      ・ 複合代入演算子? (+=,-=,*=,/=<- これら)
    ・ ~その他~
      ・ コメント
      ・ case文
      ・ include?(import?)
      ・ 構造体
  ・ 構文エラーを検出できるようにする 
  ・ エラーメッセージをちゃんと作る
  ・ てきとうすぎる変数名、関数名をどうにかする
  ・ 「仮」「後で修正」「後で変更する」とかいろいろ書いてるところを修正していく
  ・ ka23の関数名がc++の関数と競合しないようにする
]#