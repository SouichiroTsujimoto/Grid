#include "ka2lib/ka2funcs.h"

int main ( int argc , char *argv[] ) {
  auto add = [] ( char x , int y ) {
    return ( x ) ;
  } ;
  ka23::map ( { 1 , 2 , 3 } , [ add ] ( int i ) { return add ( 'a' , i ) ; } ) ;
  std::vector<int> n = { 10 } ;
}
