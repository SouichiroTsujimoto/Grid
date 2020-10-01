#include <iostream>
#include <vector>
#include <algorithm>
#include "ka2lib/ka2calc.h"
#include "ka2lib/ka2IO.h"

int main() {
  if ( _k_ee ( 1 ) ( 3 ) ) {
    _k_puts ( "ok" ) ;
  }
  else if ( _k_ne ( 4 ) ( 5 ) ) {
    _k_puts ( true ) ;
  }
  else if ( false ) {
    _k_puts ( "違う" ) ;
  }
  else {
    _k_puts ( "else" ) ;
  }
}