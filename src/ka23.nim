import  ka2parser, ka2cpp

when isMainModule:
  var input = """ def a(x) = do
                    return x * 3
                  end
                  let a = 1 + 2 + 3
                  """
  var program = makeAST(input)
  for tree in program:
    echo makeCppCode(tree)

#[
  TODO
  ・ 関数をちゃんと宣言できるようにする ✅
  ・ c++のコードに変換できるようにする
  ・ elifを実装する
  ・ 比較演算子を実装する
  ・ return文を実装する
  ・ 関数の返り値の型を指定できるようにする
]#