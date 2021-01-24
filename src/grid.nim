import  g_parser, g_rw, g_node, g_cpp, g_shaping, g_show, g_error, g_token, g_preprocessor
import strutils, system, os

var cppCode = """
#include "gridfuncs.cpp"
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
    cppFileName = ""
    peekParam = ""
    skip_flag = false

  # コマンドライン引数の処理
  for i, param in os.commandLineParams():
    if i != os.paramCount()-1:
      peekParam = os.commandLineParams()[i+1]
    else:
      peekParam = "EOP"

    if skip_flag:
      skip_flag = false
      continue

    if param[0] == '-':
      case param
      of "-ast":
        ast = true
      of "-en":
        lang = EN
      of "-jp":
        lang = JP
      of "-o":
        if peekParam != "EOP":
          cppFileName = peekParam
          skip_flag = true
        else:
          echoErrorMessage("\"-o\"の後にファイル名が指定されていません", false, -1)
      else:
        echoErrorMessage("無効なオプションが含まれています", false, -1)
    elif sourceName == "":
      sourceName = param
    else:
      echoErrorMessage("無効なコマンドライン引数が含まれています", false, -1)

  if sourceName == "":
    echo "ファイル名を入力してください"
    sourceName = readLine(stdin)
  
  if cppFileName == "":
    var file_name = sourceName.split("/")
    cppFileName = file_name[filename.len()-1].split(".")[0] & ".cpp"

  # AST作成してC++を出力
  var
    input  = sourceName.readSource()
    prepro = input.preprocess(sourceName)

  var asts   = prepro.makeAST()

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

  writeCpp(cppFileName, cppCode)

#[
  TODO
・ ~優先~
  ・ # TODO: 今日やる
    ・ '$' ✅
    ・ '&' ✅
    ・ range関数 ✅
    ・ filter関数
    ・ while文
    
  ・ テストの更新
  ・ 構造体 🔺
  ・ 複合リテラル 🔺
  ・ エラーメッセージを英語化できるようにする
  ・ リファレンス的なのを用意する
  ・ 関数リテラル
  ・ 型推論
  ・ モジュール(名前空間？)
  ・ C++の予約語との競合を避ける

・ ~配列~
  ・ 配列リテラルを関数に渡せるようにする ✅
  ・ at関数 ✅
  ・ map関数 ✅
・ ~型~
  ・ 型のキャスト 🔺
  ・ void
・ ~IO~
  ・ 標準入力 🔺

・ ~その他~
  ・ コメント ✅
  ・ case文
  ・ sum関数
  ・ 辞書型
  ・ エスケープ文字 ✅
  ・ エラーメッセージに行番号を付ける ✅
  ・ include
  ・ import
  
  ・ gridfuncs.cppを自動生成 ✅
  ・ 最適化オプション
  ・ エラーメッセージをちゃんと作る 🔺
  ・ てきとうすぎる変数名、関数名をどうにかする
]#