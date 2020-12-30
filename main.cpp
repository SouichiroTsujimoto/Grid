#include "ka2lib/ka2funcs.h"

int a = 10 ;

int hoge ( int n ) {
  return ( ( n + a ) ) ;
}
int main ( int argc , char *argv[] ) {
  ka23::println ( ka23::toString ( hoge ( 30 ) ) ) ;
  ka23::println ( ka23::toString ( hoge ( 30 ) ) ) ;
}
delete a ;
