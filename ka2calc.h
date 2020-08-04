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

void ka2_puts(std::string a) {
  std::cout << a << "\n";
}
/*
int main() {
  std::cout << ka2_mul (ka2_add (3) (2)) (4) << "\n";
}
*/