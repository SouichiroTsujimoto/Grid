#define k_map(a, b, c)({ \
  std::vector<c> _result;\
  _result.reserve(a.size());\
  std::transform(std::begin(a), std::end(a), std::back_inserter(_result), b);\
  _result;\
})


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
