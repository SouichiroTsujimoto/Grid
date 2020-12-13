#include "ka2lib/ka2funcs.h"

int main ( int argc , char *argv[] ) {
  auto a = [] ( int x ) {
    ka23::print ( ka23::toString ( x ) ) ;
    return ( x ) ;
  } ;
  ka23::print ( ka23::toString ( ka23::head ( { 1 , 2 , 3 } ) ) ) ;
}
