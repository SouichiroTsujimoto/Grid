#include "ka2lib/ka2funcs.h"

int main ( int argc , char *argv[] ) {
  const std::vector<int> a = ( std::vector<int> ) { 1 , 2 , 3 } ;
  const int b = ka23::map ( a , [] ( int _i ) { return ka23::plus ( _i , 1 ) ; } ) [ 0 ] ;
}
