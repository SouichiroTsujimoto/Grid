// #define k_map(a, b, c)({ \
//   std::vector<c> _result;\
//   _result.reserve(a.size());\
//   std::transform(begin(a), end(a), std::back_inserter(_result), b);\
//   _result;\
//   })

template<typename T, typename Y, typename R>
std::vector<T> k_map(std::vector<Y> a, R b, T c) {
  std::vector<T> _result;
  _result.reserve(a.size());
  std::transform(begin(a), end(a), std::back_inserter(_result), b);
  return _result;
};

auto k_add = [](auto a) {
  return [a](auto b) { return a + b; };
};

auto k_sub = [](auto a) {
  return [a](auto b) {return a - b;};
};

auto k_mul = [](auto a) {
  return [a](auto b) {return a * b;};
};

auto k_div = [](auto a) {
  return [a](auto b) {return a / b;};
};

auto k_lt = [](auto a) {
  return [a](auto b) {return a < b;};
};

auto k_gt = [](auto a) {
  return [a](auto b) {return a > b;};
};

auto k_le = [](auto a) {
  return [a](auto b) {return a <= b;};
};

auto k_ge = [](auto a) {
  return [a](auto b) {return a >= b;};
};

auto k_ee = [](auto a) {
  return [a](auto b) {return a == b;};
};

auto k_ne = [](auto a) {
  return [a](auto b) {return a != b;};
};

auto k_assign = [](auto *a) {
  return [a](auto b) {
    *a = b;
    return b;
  };
};
