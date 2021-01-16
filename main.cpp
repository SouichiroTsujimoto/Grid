#include "ka2lib/ka2funcs.h"

int a ( int b ) {
  const int v = 0 ;
  return ( 1 ) ;
}
int main ( int argc , char *argv[] ) {
  const int hoge = 10 ;
  const int f = [&] {
    std::vector<int> v = ( std::vector<int> ) { 0 } ;
    int x = 10 ;
    return ( ( v [ 0 ] + x ) ) ;
  } () ;
  ka23::println ( ka23::toString ( f ) ) ;
}
