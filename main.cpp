#include "ka2lib/ka2funcs.h"

int main ( int argc , char *argv[] ) {
  auto a = [] ( int x ) {
    ka23::print ( ka23::toString ( x ) ) ;
    return ( x ) ;
  } ;
  std::vector<int> * n = new std::vector<int> ;
  * n = { 1 , 2 , 3 } ;
  std::cout << ka23::tail({1, 2, 3})[0] << std::endl;
  delete n ;
}
