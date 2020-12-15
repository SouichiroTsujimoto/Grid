#include "ka2lib/ka2funcs.h"

int main ( int argc , char *argv[] ) {
  auto add = [] ( int x , int y ) {
    return ( x ) ;
  } ;
  ka23::map ( { 1 , 2 , 3 } , [ add ] ( int i ) { return add ( 1 , i ) ; } ) ;
  std::vector<int> n = { 10 } ;
}
