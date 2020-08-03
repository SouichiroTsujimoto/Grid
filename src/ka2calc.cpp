#include<iostream>

auto ka2_add = [](int a) {
  return [a](int b) { return a + b; };
};

auto ka2_sub = [](int a) {
  return [a](int b) {return a - b;};
};

auto ka2_mul = [](int a) {
  return [a](int b) {return a * b;};
};

auto ka2_div = [](int a) {
  return [a](int b) {return a / b;};
};

int main() {
  std::cout << ka2_sub(ka2_mul(ka2_add(1)(2))(3))(4) << "\n";
}