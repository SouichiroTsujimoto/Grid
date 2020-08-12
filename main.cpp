#include <iostream>
#include "ka2calc.h"

int main() {
  int expr = k_add(1)(k_mul(3)(5));
  std::cout << expr << std::endl;
}