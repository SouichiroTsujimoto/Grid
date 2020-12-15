// 〜保留〜
// #define map(a, b, c)({ \
//   std::vector<c> _result;\
//   _result.reserve(a.size());\
//   std::transform(std::begin(a), std::end(a), std::back_inserter(_result), b);\
//   _result;\
// })
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

  // len関数 TODO: 多次元配列に対応させる
  int len(std::vector<int> a) {
    return (int)a.size();
  }
  int len(std::vector<float> a) {
    return (int)a.size();
  }
  int len(std::vector<char> a) {
    return (int)a.size();
  }
  int len(std::vector<std::string> a) {
    return (int)a.size();
  }
  int len(std::vector<bool> a) {
    return (int)a.size();
  }

  // join関数 TODO: 多次元配列に対応させる
  std::vector<int> join(std::vector<int> a, std::vector<int> b) {
    std::vector<int> c;
    c.reserve(a.size() + b.size());
    c.insert(c.end(), a.begin(), a.end());
    c.insert(c.end(), b.begin(), b.end());
    return c;
  }
  std::vector<float> join(std::vector<float> a, std::vector<float> b) {
    std::vector<float> c;
    c.reserve(a.size() + b.size());
    c.insert(c.end(), a.begin(), a.end());
    c.insert(c.end(), b.begin(), b.end());
    return c;
  }
  std::vector<char> join(std::vector<char> a, std::vector<char> b) {
    std::vector<char> c;
    c.reserve(a.size() + b.size());
    c.insert(c.end(), a.begin(), a.end());
    c.insert(c.end(), b.begin(), b.end());
    return c;
  }
  std::vector<std::string> join(std::vector<std::string> a, std::vector<std::string> b) {
    std::vector<std::string> c;
    c.reserve(a.size() + b.size());
    c.insert(c.end(), a.begin(), a.end());
    c.insert(c.end(), b.begin(), b.end());
    return c;
  }
  std::vector<bool> join(std::vector<bool> a, std::vector<bool> b) {
    std::vector<bool> c;
    c.reserve(a.size() + b.size());
    c.insert(c.end(), a.begin(), a.end());
    c.insert(c.end(), b.begin(), b.end());
    return c;
  }

  void print(char a) {
    std::cout << a;
  }
  void print(std::string a) {
    std::cout << a;
  }

  void println(char a) {
    std::cout << a << "\n";
  }
  void println(std::string a) {
    std::cout << a << "\n";
  }

  int head(std::vector<int> a) {
    return a[0];
  }
  int head(std::initializer_list<int> a) {
    std::vector<int> b = a;
    return b[0];
  }
  float head(std::vector<float> a) {
    return a[0];
  }
  float head(std::initializer_list<float> a) {
    std::vector<float> b = a;
    return b[0];
  }
  char head(std::vector<char> a) {
    return a[0];
  }
  char head(std::initializer_list<char> a) {
    std::vector<char> b = a;
    return b[0];
  }
  std::string head(std::vector<std::string> a) {
    return a[0];
  }
  std::string head(std::initializer_list<std::string> a) {
    std::vector<std::string> b = a;
    return b[0];
  }
  bool head(std::vector<bool> a) {
    return a[0];
  }
  bool head(std::initializer_list<bool> a) {
    std::vector<bool> b = a;
    return b[0];
  }

  std::vector<int> tail(std::vector<int> a) {
    std::vector<int> b(a.size()-1);
    copy(a.begin()+1, a.end(), b.begin());
    return b;
  }
  std::vector<int> tail(std::initializer_list<int> a) {
    std::vector<int> b(a.size()-1);
    copy(a.begin()+1, a.end(), b.begin());
    return b;
  }
  std::vector<float> tail(std::vector<float> a) {
    std::vector<float> b(a.size()-1);
    copy(a.begin()+1, a.end(), b.begin());
    return b;
  }
  std::vector<float> tail(std::initializer_list<float> a) {
    std::vector<float> b(a.size()-1);
    copy(a.begin()+1, a.end(), b.begin());
    return b;
  }
  std::vector<char> tail(std::vector<char> a) {
    std::vector<char> b(a.size()-1);
    copy(a.begin()+1, a.end(), b.begin());
    return b;
  }
  std::vector<char> tail(std::initializer_list<char> a) {
    std::vector<char> b(a.size()-1);
    copy(a.begin()+1, a.end(), b.begin());
    return b;
  }
  std::vector<std::string> tail(std::vector<std::string> a) {
    std::vector<std::string> b(a.size()-1);
    copy(a.begin()+1, a.end(), b.begin());
    return b;
  }
  std::vector<std::string> tail(std::initializer_list<std::string> a) {
    std::vector<std::string> b(a.size()-1);
    copy(a.begin()+1, a.end(), b.begin());
    return b;
  }
  std::vector<bool> tail(std::vector<bool> a) {
    std::vector<bool> b(a.size()-1);
    copy(a.begin()+1, a.end(), b.begin());
    return b;
  }
  std::vector<bool> tail(std::initializer_list<bool> a) {
    std::vector<bool> b(a.size()-1);
    copy(a.begin()+1, a.end(), b.begin());
    return b;
  }

  int last(std::vector<int> a) {
    return a.back();
  }
  int last(std::initializer_list<int> a) {
    std::vector<int> b = a;
    return b.back();
  }
  float last(std::vector<float> a) {
    return a.back();
  }
  float last(std::initializer_list<float> a) {
    std::vector<float> b = a;
    return b.back();
  }
  char last(std::vector<char> a) {
    return a.back();
  }
  char last(std::initializer_list<char> a) {
    std::vector<char> b = a;
    return b.back();
  }
  std::string last(std::vector<std::string> a) {
    return a.back();
  }
  std::string last(std::initializer_list<std::string> a) {
    std::vector<std::string> b = a;
    return b.back();
  }
  bool last(std::vector<bool> a) {
    return a.back();
  }
  bool last(std::initializer_list<bool> a) {
    std::vector<bool> b = a;
    return b.back();
  }

  std::vector<int> init(std::vector<int> a) {
    std::vector<int> b(a.size()-1);
    copy(a.begin(), a.end()-1, b.begin());
    return b;
  }
  std::vector<int> init(std::initializer_list<int> a) {
    std::vector<int> b(a.size()-1);
    copy(a.begin(), a.end()-1, b.begin());
    return b;
  }
  std::vector<float> init(std::vector<float> a) {
    std::vector<float> b(a.size()-1);
    copy(a.begin(), a.end()-1, b.begin());
    return b;
  }
  std::vector<float> init(std::initializer_list<float> a) {
    std::vector<float> b(a.size()-1);
    copy(a.begin(), a.end()-1, b.begin());
    return b;
  }
  std::vector<char> init(std::vector<char> a) {
    std::vector<char> b(a.size()-1);
    copy(a.begin(), a.end()-1, b.begin());
    return b;
  }
  std::vector<char> init(std::initializer_list<char> a) {
    std::vector<char> b(a.size()-1);
    copy(a.begin(), a.end()-1, b.begin());
    return b;
  }
  std::vector<std::string> init(std::vector<std::string> a) {
    std::vector<std::string> b(a.size()-1);
    copy(a.begin(), a.end()-1, b.begin());
    return b;
  }
  std::vector<std::string> init(std::initializer_list<std::string> a) {
    std::vector<std::string> b(a.size()-1);
    copy(a.begin(), a.end()-1, b.begin());
    return b;
  }
  std::vector<bool> init(std::vector<bool> a) {
    std::vector<bool> b(a.size()-1);
    copy(a.begin(), a.end()-1, b.begin());
    return b;
  }
  std::vector<bool> init(std::initializer_list<bool> a) {
    std::vector<bool> b(a.size()-1);
    copy(a.begin(), a.end()-1, b.begin());
    return b;
  }

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

  std::vector<int> map(std::vector<int> a, std::function<int(int)> b) {
    std::vector<int> c = {};
    for(int d : a) {
      c.push_back(b(d));
    }
    return c;
  }
  std::vector<int> map(std::initializer_list<int> a, std::function<int(int)> b) {
    std::vector<int> c = {};
    for(int d : a) {
      c.push_back(b(d));
    }
    return c;
  }
  std::vector<float> map(std::vector<float> a, std::function<float(float)> b) {
    std::vector<float> c = {};
    for(float d : a) {
      c.push_back(b(d));
    }
    return c;
  }
  std::vector<float> map(std::initializer_list<float> a, std::function<float(float)> b) {
    std::vector<float> c = {};
    for(float d : a) {
      c.push_back(b(d));
    }
    return c;
  }
  std::vector<char> map(std::vector<char> a, std::function<char(char)> b) {
    std::vector<char> c = {};
    for(char d : a) {
      c.push_back(b(d));
    }
    return c;
  }
  std::vector<char> map(std::initializer_list<char> a, std::function<char(char)> b) {
    std::vector<char> c = {};
    for(char d : a) {
      c.push_back(b(d));
    }
    return c;
  }
  std::vector<std::string> map(std::vector<std::string> a, std::function<std::string(std::string)> b) {
    std::vector<std::string> c = {};
    for(std::string d : a) {
      c.push_back(b(d));
    }
    return c;
  }
  std::vector<std::string> map(std::initializer_list<std::string> a, std::function<std::string(std::string)> b) {
    std::vector<std::string> c = {};
    for(std::string d : a) {
      c.push_back(b(d));
    }
    return c;
  }
  std::vector<bool> map(std::vector<bool> a, std::function<bool(bool)> b) {
    std::vector<bool> c = {};
    for(bool d : a) {
      c.push_back(b(d));
    }
    return c;
  }
  std::vector<bool> map(std::initializer_list<bool> a, std::function<bool(bool)> b) {
    std::vector<bool> c = {};
    for(bool d : a) {
      c.push_back(b(d));
    }
    return c;
  }

}