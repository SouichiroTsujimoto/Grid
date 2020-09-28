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
  ・ 意味解析
    ・ 変数の名前と型を記憶するテーブルを作る ✅
  ・ エラーが出たらコンパイルを止める ✅
  ・ ちゃんとテストができるように修正する ✅
  ・ 変数をイミュータブルに ✅
  ・ ミュータブルな変数も作る  ✅
  ・ 代入式を作る ✅
  ・ イミュータブルな変数に値を代入できないようにする ✅
  ・ 配列実装
    ・ Array型を作る ✅
    ・ 可変長の配列も作る ✅
    ・ 型のチェック ✅
  ・ map関数 ✅
  ・ for文 ✅
  ・ 演算子、代入式をINT以外の型にも対応させる ✅
  ・ 関数の引数の型のチェック ✅
  ・ generatorの型のチェック ✅
  ・ 組み込み関数とユーザー定義関数が競合しないようにする ✅
  ・ パイプライン関数
  ・ case式
  ・ コメントを実装
  ・ 構文エラーを検出できるようにする 
  ・ エラーメッセージをちゃんと作る
  ・ てきとうすぎる変数名、関数名をどうにかする
  ・ 「仮」「後で修正」「後で変更する」とかいろいろ書いてるところを修正していく
  ・ ka23の関数名がc++の関数と競合しないようにする
]#