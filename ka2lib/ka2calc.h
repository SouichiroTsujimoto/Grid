// 〜保留〜
// #define _k_map(a, b, c)({ \
//   std::vector<c> _result;\
//   _result.reserve(a.size());\
//   std::transform(std::begin(a), std::end(a), std::back_inserter(_result), b);\
//   _result;\
// })

auto _k_add = [](auto a) {
  return [a](auto b) { return a + b; };
};

auto _k_sub = [](auto a) {
  return [a](auto b) {return a - b;};
};

auto _k_mul = [](auto a) {
  return [a](auto b) {return a * b;};
};

auto _k_div = [](auto a) {
  return [a](auto b) {return a / b;};
};

auto _k_lt = [](auto a) {
  return [a](auto b) {return a < b;};
};

auto _k_gt = [](auto a) {
  return [a](auto b) {return a > b;};
};

auto _k_le = [](auto a) {
  return [a](auto b) {return a <= b;};
};

auto _k_ge = [](auto a) {
  return [a](auto b) {return a >= b;};
};

auto _k_ee = [](auto a) {
  return [a](auto b) {return a == b;};
};

auto _k_ne = [](auto a) {
  return [a](auto b) {return a != b;};
};

auto _k_len = [](auto a) {
  return (int)a.size();
};

auto _k_join = [](std::vector<int> a) {
  return [a](std::vector<int> b) {
    std::vector<int> c;
    c.reserve(a.size() + b.size());
    c.insert(c.end(), a.begin(), a.end());
    c.insert(c.end(), b.begin(), b.end());
    return c;
  };
};
