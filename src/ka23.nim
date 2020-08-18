import  ka2parser, ka2cpp, ka2rw
import strutils

var cppCode = """
#include<iostream>
#include<stdio.h>
#include "ka2calc.h"

int main() {
"""

when isMainModule:
  let sourceName = readLine(stdin)
  let input = sourceName.readSource()
  let program = makeAST(input)
  
  for tree in program:
    cppCode.add(makeCppCode(tree, 0))
  cppCode.add("\n}")
  
  let cppFileName = sourceName.split(".")[0] & ".cpp"
  writeCpp(cppFileName, cppCode)
#[
  TODO
  ・ 関数をちゃんと宣言できるようにする ✅
  ・ return文を実装する ✅
  ・ 比較演算子を実装する ✅
  ・ elifを実装する  ✅
  ・ 関数の返り値の型を指定できるようにする ✅
  ・ ファイル読み込み・ファイル書き出しできるようにする ✅
  ・ c++のコードに変換できるようにする ✅
  ・ str.add(";")問題を解決させる ✅
  ・ if文を式にする [途中]
  ・ ka23の関数名がc++の関数と競合しないようにする
  ・ 簡単にc++の関数を呼び出せるようにする
  ・ 意味解析
  ・ コメントを実装
]#