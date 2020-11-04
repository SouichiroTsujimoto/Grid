#include <iostream>
#include <algorithm>
#include "ka2lib/ka2funcs.h"

int a ( int b , int c ) {
  return ( ( b / c ) ) ;
}
int main ( int argc , char *argv[] ) {
  ka23::print ( a ( 4 , 2 ) ) ;
}
