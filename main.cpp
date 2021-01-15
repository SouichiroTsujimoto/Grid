#include "ka2lib/ka2funcs.h"

int a ( int b ) {
  const int v = 0 ;
  return ( 1 ) ;
}
int main ( int argc , char *argv[] ) {
  const int hoge = 10 ;
  const int f = [&] {
    int v = 0 ;
    int x = 10 ;
    v = ( 30 + x ) ;
    ka23::println ( ka23::toString ( v ) ) ;
    return ( v ) ;
  } () ;
  ka23::println ( ka23::toString ( f ) ) ;
}
