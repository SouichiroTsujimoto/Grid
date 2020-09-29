#include <iostream>
#include <vector>
#include <algorithm>
#include "ka2lib/ka2calc.h"
#include "ka2lib/ka2IO.h"

int main() {
  if ( _k_ee ( 1 ) ( 3 ) ) {
    return ( "ok" ) ;
  }
  elif ( _k_ne ( 4 ) ( 5 ) ) {
    return ( true ) ;
  }
  elif ( false ) {
    return ( "違う" ) ;
  }
  else {
    return ( "else" ) ;
  }
}