#include "ka2lib/ka2funcs.h"

int a ( int b , int c ) {
  return ( ( ( b + c ) * 2 ) ) ;
}
int main ( int argc , char *argv[] ) {
  ka23::print ( a ( 10 , 20 ) ) ;
}
