proc echoErrorMessage*(number: int, test: bool) =
  # I majide wakaran English.

  case number
  of 0:
    echo "配列内の要素の型が全て同じになっていません[0]"
  of 1:
    echo "型指定の後に名前が書かれていません[1]"
  of 2:
    echo "定義されていない名前です[2]"
  of 3:
    echo "既に定義されています[3]"
  of 4:
    echo "指定している型と値の型が違います[4]"
  of 5:
    echo "指定している型と返り値の型が違います[5]"
  of 6:
    echo "式がありません[6]"
  of 7:
    echo "オペランドがありません[7]"
  of 8:
    echo "オペランドの型が間違っています[8]"
  of 9:
    echo "オペランドの型がそれぞれ違います[9]"
  of 10:
    echo "無効なインデックスです[10]"
  of 11:
    echo "代入しようとしている変数がイミュータブルです[11]"
  of 12:
    echo "返り値の型が異なっています[12]"
  of 13:
    echo "引数の数が足りていません[13]"
  else:
    echo "不明なエラー"
  
  if test == false:
    quit()
