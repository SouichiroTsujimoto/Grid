#include "ka2lib/ka2funcs.h"

std::vector<int> hoge ( std::vector<int> x ) {
  return ( x ) ;
}
int main ( int argc , char *argv[] ) {
  ka23::map ( ( std::vector<std::vector<int>> ) { ( std::vector<int> ) { 1 , 2 } , ( std::vector<int> ) { 3 , 4 } } , [] ( std::vector<int> _i ) { return hoge ( _i ) ; } ) ;
}
