#include <iostream>
#include <vector>
#include <algorithm>
#include "ka2lib/ka2calc.h"
#include "ka2lib/ka2IO.h"

int main() {
  const int a = ( _k_ee ( _k_add ( 2 ) ( 2 ) ) ( 5 ) ? 1984 : ( _k_ee ( _k_add ( 2 ) ( 2 ) ) ( 4 ) ? 2020 : 0 ) ) ;
  _k_puts ( a ) ;

}