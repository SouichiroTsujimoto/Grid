#include <iostream>
#include <vector>
#include <algorithm>
#include "ka2lib/ka2calc.h"
#include "ka2lib/ka2IO.h"

int main() {
  int x = 0 ;
  for ( int a : { 1 , 2 , 3 } ) {
    x = k_add ( x ) ( a ) ;
  } 

}