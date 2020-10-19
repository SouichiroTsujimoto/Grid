import  ka2parser, ka2rw, ka2node
import strutils

var cppCode = """
#include <iostream>
#include <vector>
#include <algorithm>
#include "ka2lib/ka2calc.h"
#include "ka2lib/ka2IO.h"

int main() {
"""

proc showAST(node: Node, indent: int): string =
  for i in 0..indent-1:
    result.add("  ")
  result.add("{:" & $node.kind & ", [Type:" & $node.token.Type & ", Literal:" & $node.token.Literal & "], [")
  for child in node.child_nodes:
    result.add("\n")
    result.add(showAST(child, indent + 1))
  for i in 0..indent-1:
    result.add("  ")
  result.add("]}\n")

when isMainModule:
  # echo "ファイル名を入力してください"
  # let sourceName = readLine(stdin)
  let sourceName = "main.ka23"
  let input = sourceName.readSource()
  let program = makeAST(input)
  let test = false

  echo showAST(program[0], 0)

  # for tree in program:
  #   cppCode.add(makeCppCode(tree, 0, test))
  # cppCode.add("\n}")

  # let cppFileName = sourceName.split(".")[0] & ".cpp"
  # writeCpp(cppFileName, cppCode)

  
#[
  TODO
  ・ if文 ✅
  ・ パイプライン演算子 ✅
  ・ 【急遽】 負の数実装 ✅
  ・ plus, minus, multiply, divide関数を作る ✅
  ・ 機能を増やす
    ・ ~配列~
      ・ 要素へのアクセス (hoge[0]<- これ) ✅
      ・ len関数 ✅
      ・ 配列の連結
      ・ head, tail, last, init関数
    ・ ~変数~
      ・ 型のキャスト
      ・ 複合代入演算子? (+=,-=,*=,/=<- これら)
    ・ ~その他~
      ・ コメント
      ・ case文
      ・ include?(import?)
      ・ 構造体
      ・ map関数
      ・ filter関数
      ・ エスケープ文字
  ・ エラーメッセージをちゃんと作る 🔺
  ・ 構文エラーを検出できるようにする 
  ・ エラーメッセージに行番号を付ける
  ・ エラーメッセージを英語化できるようにする
  ・ てきとうすぎる変数名、関数名をどうにかする
  ・ 「仮」「後で修正」「後で変更する」とかいろいろ書いてるところを修正していく
  ・ ka23の関数名がc++の関数と競合しないようにする
]#