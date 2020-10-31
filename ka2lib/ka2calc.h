// 〜保留〜
// #define _k_map(a, b, c)({ \
//   std::vector<c> _result;\
//   _result.reserve(a.size());\
//   std::transform(std::begin(a), std::end(a), std::back_inserter(_result), b);\
//   _result;\
// })

int _k_plus(int a, int b) {
  return a + b;
}
float _k_plus(float a, float b) {
  return a + b;
}

int _k_minu(int a, int b) {
  return a - b;
}
float _k_minu(float a, float b) {
  return a - b;
}

int _k_mult(int a, int b) {
  return a * b;
}
float _k_mult(float a, float b) {
  return a * b;
}

int _k_divi(int a, int b) {
  return a / b;
}
float _k_divi(float a, float b) {
  return a / b;
}

// lt関数
bool _k_lt(int a, int b) {
  return a < b;
}
bool _k_lt(float a, float b) {
  return a < b;
}

// gt関数
bool _k_gt(int a, int b) {
  return a > b;
}
bool _k_gt(float a, float b) {
  return a > b;
}

// le関数
bool _k_le(int a, int b) {
  return a <= b;
}
bool _k_le(float a, float b) {
  return a <= b;
}

// ge関数
bool _k_ge(int a, int b) {
  return a >= b;
}
bool _k_ge(float a, float b) {
  return a >= b;
}

// ee関数
bool _k_ee(int a, int b) {
  return a == b;
}
bool _k_ee(float a, float b) {
  return a == b;
}
bool _k_ee(char a, char b) {
  return a == b;
}
bool _k_ee(std::string a, std::string b) {
  return a == b;
}
bool _k_ee(bool a, bool b) {
  return a == b;
}

// ne関数
bool _k_ne(int a, int b) {
  return a != b;
}
bool _k_ne(float a, float b) {
  return a != b;
}
bool _k_ne(char a, char b) {
  return a != b;
}
bool _k_ne(std::string a, std::string b) {
  return a != b;
}
bool _k_ne(bool a, bool b) {
  return a != b;
}

// len関数 TODO: 多次元配列に対応させる
int _k_len(std::vector<int> a) {
  return (int)a.size();
}
int _k_len(std::vector<float> a) {
  return (int)a.size();
}
int _k_len(std::vector<char> a) {
  return (int)a.size();
}
int _k_len(std::vector<std::string> a) {
  return (int)a.size();
}
int _k_len(std::vector<bool> a) {
  return (int)a.size();
}

// join関数 TODO: 多次元配列に対応させる
std::vector<int> _k_join(std::vector<int> a, std::vector<int> b) {
  std::vector<int> c;
  c.reserve(a.size() + b.size());
  c.insert(c.end(), a.begin(), a.end());
  c.insert(c.end(), b.begin(), b.end());
  return c;
}
std::vector<float> _k_join(std::vector<float> a, std::vector<float> b) {
  std::vector<float> c;
  c.reserve(a.size() + b.size());
  c.insert(c.end(), a.begin(), a.end());
  c.insert(c.end(), b.begin(), b.end());
  return c;
}
std::vector<char> _k_join(std::vector<char> a, std::vector<char> b) {
  std::vector<char> c;
  c.reserve(a.size() + b.size());
  c.insert(c.end(), a.begin(), a.end());
  c.insert(c.end(), b.begin(), b.end());
  return c;
}
std::vector<std::string> _k_join(std::vector<std::string> a, std::vector<std::string> b) {
  std::vector<std::string> c;
  c.reserve(a.size() + b.size());
  c.insert(c.end(), a.begin(), a.end());
  c.insert(c.end(), b.begin(), b.end());
  return c;
}
std::vector<bool> _k_join(std::vector<bool> a, std::vector<bool> b) {
  std::vector<bool> c;
  c.reserve(a.size() + b.size());
  c.insert(c.end(), a.begin(), a.end());
  c.insert(c.end(), b.begin(), b.end());
  return c;
}

// auto _k_head = [](auto a) {
//   return a[0];
// };