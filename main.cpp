#include <iostream>
#include "ka2calc.h"

int main() {
  int expr = ka2_mul (ka2_add (3) (2)) (4);
  std::cout << expr << std::endl;
}