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

  // std::vector<int> map(std::vector<int> a, std::function<int(int)> b) {
  //   std::vector<int> c = {};
  //   for(int d : a) {
  //     c.push_back(b(d));
  //   }
  //   return c;
  // }
  // std::vector<int> map(std::initializer_list<int> a, std::function<int(int)> b) {
  //   std::vector<int> c = {};
  //   for(int d : a) {
  //     c.push_back(b(d));
  //   }
  //   return c;
  // }
  // std::vector<float> map(std::vector<float> a, std::function<float(float)> b) {
  //   std::vector<float> c = {};
  //   for(float d : a) {
  //     c.push_back(b(d));
  //   }
  //   return c;
  // }
  // std::vector<float> map(std::initializer_list<float> a, std::function<float(float)> b) {
  //   std::vector<float> c = {};
  //   for(float d : a) {
  //     c.push_back(b(d));
  //   }
  //   return c;
  // }
  // std::vector<char> map(std::vector<char> a, std::function<char(char)> b) {
  //   std::vector<char> c = {};
  //   for(char d : a) {
  //     c.push_back(b(d));
  //   }
  //   return c;
  // }
  // std::vector<char> map(std::initializer_list<char> a, std::function<char(char)> b) {
  //   std::vector<char> c = {};
  //   for(char d : a) {
  //     c.push_back(b(d));
  //   }
  //   return c;
  // }
  // std::vector<std::string> map(std::vector<std::string> a, std::function<std::string(std::string)> b) {
  //   std::vector<std::string> c = {};
  //   for(std::string d : a) {
  //     c.push_back(b(d));
  //   }
  //   return c;
  // }
  // std::vector<std::string> map(std::initializer_list<std::string> a, std::function<std::string(std::string)> b) {
  //   std::vector<std::string> c = {};
  //   for(std::string d : a) {
  //     c.push_back(b(d));
  //   }
  //   return c;
  // }
  // std::vector<bool> map(std::vector<bool> a, std::function<bool(bool)> b) {
  //   std::vector<bool> c = {};
  //   for(bool d : a) {
  //     c.push_back(b(d));
  //   }
  //   return c;
  // }
  // std::vector<bool> map(std::initializer_list<bool> a, std::function<bool(bool)> b) {
  //   std::vector<bool> c = {};
  //   for(bool d : a) {
  //     c.push_back(b(d));
  //   }
  //   return c;
  // }

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
