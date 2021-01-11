import ka2error
import system, os

var funcs_code = """
#include <iostream>
#include <string>
#include <vector>
#include <functional>

namespace ka23 {
  int plus(int a, int b) {
    return a + b;
  }
  float plus(float a, float b) {
    return a + b;
  }

  int minu(int a, int b) {
    return a - b;
  }
  float minu(float a, float b) {
    return a - b;
  }

  int mult(int a, int b) {
    return a * b;
  }
  float mult(float a, float b) {
    return a * b;
  }

  int divi(int a, int b) {
    return a / b;
  }
  float divi(float a, float b) {
    return a / b;
  }

  // lt関数
  bool lt(int a, int b) {
    return a < b;
  }
  bool lt(float a, float b) {
    return a < b;
  }

  // gt関数
  bool gt(int a, int b) {
    return a > b;
  }
  bool gt(float a, float b) {
    return a > b;
  }

  // le関数
  bool le(int a, int b) {
    return a <= b;
  }
  bool le(float a, float b) {
    return a <= b;
  }

  // ge関数
  bool ge(int a, int b) {
    return a >= b;
  }
  bool ge(float a, float b) {
    return a >= b;
  }

  // ee関数
  bool ee(int a, int b) {
    return a == b;
  }
  bool ee(float a, float b) {
    return a == b;
  }
  bool ee(char a, char b) {
    return a == b;
  }
  bool ee(std::string a, std::string b) {
    return a == b;
  }
  bool ee(bool a, bool b) {
    return a == b;
  }

  // ne関数
  bool ne(int a, int b) {
    return a != b;
  }
  bool ne(float a, float b) {
    return a != b;
  }
  bool ne(char a, char b) {
    return a != b;
  }
  bool ne(std::string a, std::string b) {
    return a != b;
  }
  bool ne(bool a, bool b) {
    return a != b;
  }

  void print(int a) {
    std::string b = std::to_string(a);
    std::cout << b;
  }
  void print(float a) {
    std::string b = std::to_string(a);
    std::cout << b;
  }
  void print(char a) {
    std::string b = std::to_string(a);
    std::cout << b;
  }
  void print(std::string a) {
    std::cout << a;
  }
  void print(bool a) {
    std::string b = std::to_string(a);
    std::cout << b;
  }

  void println(int a) {
    std::string b = std::to_string(a);
    std::cout << b << "\n";
  }
  void println(float a) {
    std::string b = std::to_string(a);
    std::cout << b << "\n";
  }
  void println(char a) {
    std::string b = std::to_string(a);
    std::cout << b << "\n";
  }
  void println(std::string a) {
    std::cout << a << "\n";
  }
  void println(bool a) {
    std::string b = std::to_string(a);
    std::cout << b << "\n";
  }
  
  auto len = [](auto a) -> int {
    return (int)a.size();
  };

  auto join = [](auto a, auto b) {
    decltype(a) c;
    c.reserve(a.size() + b.size());
    c.insert(c.end(), a.begin(), a.end());
    c.insert(c.end(), b.begin(), b.end());
    return c;
  };

  auto head = [](auto a) {
    return a[0];
  };

  auto tail = [](auto a) {
    decltype(a) b(a.size()-1);
    copy(a.begin()+1, a.end(), b.begin());
    return b;
  };

  auto last = [](auto a) {
    return a.back();
  };

  auto init = [](auto a) {
    decltype(a) b(a.size()-1);
    copy(a.begin(), a.end()-1, b.begin());
    return b;
  };

  std::string toString(int a) {
    return std::to_string(a);
  }
  std::string toString(float a) {
    return std::to_string(a);
  }
  std::string toString(char a) {
    return std::to_string(a);
  }
  std::string toString(std::string a) {
    return a;
  }
  std::string toString(bool a) {
    if (a) {
      return "true";
    }
    else {
      return "false";
    }
  }

  auto at = [](auto a, auto b) {
    return a[b];
  };

  auto map = [](auto a, auto b) {
    decltype(a) c = {};
    for(auto d : a) {
      c.push_back(b(d));
    }
    return c;
  };

  std::string readln () {
    std::string a = "";
    std::cin >> a;
    return a;
  }

}
"""

proc readSource*(name: string): string =
  if os.existsFile(name):
    var f: File = open(name , FileMode.fmRead)
    defer: close(f)

    if os.existsDir("ka2lib") == false:
      os.createDir("ka2lib")
    
    if os.existsFile("ka2lib/ka2funcs.h") == false:
      echo "ファイル作ります"
      var f: File = open("ka2lib/ka2funcs.h" ,FileMode.fmWrite)
      defer: close(f)
      f.write(funcs_code)

    return f.readAll()
  else:
    echoErrorMessage("そのファイルは存在しません", false, -1)

proc writeCpp*(name: string, code: string) =
  var f: File = open(name ,FileMode.fmWrite)
  defer: close(f)
  f.write(code)