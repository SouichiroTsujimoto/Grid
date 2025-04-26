# Grid

[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)
[![SecHack365](https://img.shields.io/badge/SecHack365-2020-ffd700.svg)](https://sechack365.nict.go.jp/)

2020年度SecHack365で開発したAltC++言語です。

# 使い方

## 実行方法

clone後、Gridディレクトリ内で
```
nimble build
```
を実行することでGrid/binに実行ファイルが生成されます。

```
$ ./bin/grid
  # -> ソースファイル名を入力 -> C++ファイルを生成

$ ./bin/grid [ソースファイル名]
  # -> C++ファイルを生成

$ ./bin/grid [ソースファイル名] [コンパイルオプション]
  # -> C++ファイルを生成
```
生成するC++ファイルと同じディレクトリにgridfuncs.cppがない場合、実行時に生成されます。


```
$ g++ [生成されたC++ファイル名] -std=c++20

$ clang++ [生成されたC++ファイル名] -std=c++20
```
生成されたC++はGCC 10.1以降またはClang 11.0以降でコンパイルすることを推奨します。
gridfuncs.cppが同じディレクトリに存在しないとコンパイルできません

## コンパイルオプション
| オプション | 動作 |
|:-----------|:------------|
| -o [ファイルパス] | 出力先を指定 |
| -ast | 実行時に生成されたASTを画面に出力 |

# ドキュメント

https://gist.github.com/SouichirouTujimoto/ccf7882e7ed77e5cf01607be46cc00e5
