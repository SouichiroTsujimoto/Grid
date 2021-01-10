import  ka2parser, ka2rw, ka2node, ka2cpp, ka2shaping, ka2show, ka2error, ka2token
import strutils, system, os

var cppCode = """
#include "ka2lib/ka2funcs.h"

"""

type Lang = enum
  JP
  EN

when isMainModule:
  var
    sourceName: string
    options: seq[string]
    main_flag = false
    test = false
    ast = false
    lang: Lang = JP

  # コマンドライン引数の処理
  for param in os.commandLineParams():
    if param[0] == '-':
      options.add(param[1..param.len()-1])
    elif sourceName == "":
      sourceName = param
    else:
      echoErrorMessage("無効なコマンドライン引数が含まれています", false, -1)
  
  # オプション
  for option in options:
    case option
    of "ast":
      ast = true
    of "en":
      lang = EN
    of "jp":
      lang = JP
    else:
      echoErrorMessage("無効なオプションが含まれています", false, -1)

  # ソースファイル
  if sourceName == "":
    echo "ファイル名を入力してください"
    sourceName = readLine(stdin)
  else:
    sourceName = os.commandLineParams()[0]

  # AST作成してC++を出力
  var
    input = sourceName.readSource()
    asts = makeAST(input)

  (asts, main_flag) = astShaping(asts, main_flag, test)
  var root = Node(
    kind:        nkRoot,
    token:       Token(Type: "", Literal: ""),
    child_nodes: asts,
  )

  if ast:
    echo showAST(root, 0)

  if main_flag == false:
    echoErrorMessage("main文が記述されていません", test, -1)
  
  cppCode.add(makeCppCode(root, 0, test))

  let cppFileName = sourceName.split(".")[0] & ".cpp"
  
  writeCpp(cppFileName, cppCode)


#[
  TODO
  ・ 変数のスコープチェックの仕方を変える
  ・ エラーメッセージのテストも作る
  ・ 【優先】テストの更新 ✅
  ・ 関数の型チェック ✅
  ・ 括弧が二重になってるところを直す
  ・ 機能を増やす
    ・ ~配列~
      ・ 配列リテラルを関数に渡せるようにする ✅
      ・ at関数 ✅
    ・ ~変数
      ・ 型のキャスト
    ・ ~IO~
      ・ 標準入力 △
    ・ ~その他~
      ・ コメント ✅
      ・ case文
      ・ include?(import?)
      ・ 構造体
      ・ 辞書型
      ・ map関数 ✅
      ・ filter関数
      ・ エスケープ文字
  ・ エラーメッセージに行番号を付ける ✅
  
  ・ ＜エラーメッセージを英語化できるようにする＞
  ・ ＜テストの更新＞
  
  ・ ka2funcsを自動生成 ✅
  ・ 最適化オプション
  ・ エラーメッセージをちゃんと作る 🔺
  ・ 構文エラーを検出できるようにする 
  ・ てきとうすぎる変数名、関数名をどうにかする
  ・ 「仮」「後で修正」「後で変更する」とかいろいろ書いてるところを修正していく
  ・ リファレンス的なのを用意する 
]#