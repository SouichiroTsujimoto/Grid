import  ka2parser, ka2rw, ka2node, ka2cpp, ka2shaping, ka2show
import strutils

var cppCode = """
#include <iostream>
#include <algorithm>
#include "ka2lib/ka2funcs.h"

"""

when isMainModule:
  # echo "ファイル名を入力してください"
  # let sourceName = readLine(stdin)
  let sourceName = "main.ka23"
  let input = sourceName.readSource()
  var program = makeAST(input)
  let test = false

  program = astShaping(program)
  echo showASTs(program)
  for tree in program:
    cppCode.add(makeCppCode(tree, 0, test))

  let cppFileName = sourceName.split(".")[0] & ".cpp"
  writeCpp(cppFileName, cppCode)


#[
  TODO
  ・ 変数のスコープ管理がなんかバグってる(ka2cppの563行目辺り)
  ・ エラーメッセージのテストも作る
  ・ 関数をちゃんとmain関数の外で定義するように ✅
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