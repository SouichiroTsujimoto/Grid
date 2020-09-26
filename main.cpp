#include <iostream>
#include <vector>
#include <algorithm>
#include "ka2lib/ka2calc.h"
#include "ka2lib/ka2IO.h"

int main() {
  std::vector<int> _jfdouinfiesmnflajfuiaj = {1 ,2, 3};
  std::vector<int> _result = k_map(_jfdouinfiesmnflajfuiaj, k_add(1), int);
  k_puts(_result[0]);
}