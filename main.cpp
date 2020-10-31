#include <iostream>
#include <vector>
#include <algorithm>
#include "ka2lib/ka2calc.h"
#include "ka2lib/ka2IO.h"

int main() {
  const int a = _k_mult ( _k_minu ( 1 , _k_plus ( 2 , 3 ) ) , 4 ) ;
  _k_puts ( a ) ;

}