#include <iostream>
#include <vector>
#include <algorithm>
#include "ka2lib/ka2calc.h"
#include "ka2lib/ka2IO.h"

int main() {
  std::vector<int> a = { 1 , 2 } ;
  _k_push_back ( a ) ( 3 ) ;
  for ( int i : a ) {
    _k_puts ( i ) ;
  }

}