#include <iostream>
#include <vector>
#include <algorithm>
#include "ka2lib/ka2calc.h"
#include "ka2lib/ka2IO.h"

int main() {
  const std::vector<int> a = _k_join ( _k_join ( _k_join ( _k_join ( { 1 , 2 } ) ( { 3 , 4 } ) ) ( _k_join ( { 1 , 2 } ) ( { 3 , 4 } ) ) ) ( { 1 , 2 } ) ) ( { 1 , 2 } ) ;
  _k_puts ( a [ 11 ] ) ;

}