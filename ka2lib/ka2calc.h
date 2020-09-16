#define k_map(a, b)({ \
  std::vector<int> _result = a;\
  std::transform(a.begin(), a.end(), _result.begin(), [](decltype(a[0]) i) {\
    return b(i);\
  });\
  _result; \
  });

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

auto k_eq = [](auto a) {
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
