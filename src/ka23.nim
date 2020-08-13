import  ka2parser, ka2cpp

when isMainModule:
  var input = """ let a = 10
                  if a != 6 do
                    return 90
                  else
                    return 1 + 3
                  end
                  def nibai(x) = do
                    return x * 2
                  end
                  let a = 1
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
  ・ elifを実装する 
  ・ 関数の返り値の型を指定できるようにする
]#