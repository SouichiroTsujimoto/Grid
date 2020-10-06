#include <iostream>
#include <vector>
#include <algorithm>
#include "ka2lib/ka2calc.h"
#include "ka2lib/ka2IO.h"

int main() {
  const std::vector<int> a = { 1 , 2 , 3 } ;
  _k_puts ( _k_add ( a [ -1 ] ) ( 3 ) ) ;

}