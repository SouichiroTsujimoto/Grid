import  ka2parser, ka2cpp

when isMainModule:
  var input = """ def int nibai(a) do
                    return a * 2
                  end
                  let string txt = "String"
              """
  var program = makeAST(input)
  for tree in program:
    echo makeCppCode(tree)

#[
  TODO
  ・ 関数をちゃんと宣言できるようにする ✅
  ・ c++のコードに変換できるようにする (ｰ ｰ;)
  ・ return文を実装する ✅
  ・ 比較演算子を実装する ✅
  ・ elifを実装する  ✅
  ・ 関数の返り値の型を指定できるようにする ✅
  ・ ファイル読み込み・ファイル書き出しできるようにする
]#