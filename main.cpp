#include "ka2lib/ka2funcs.h"

int main ( int argc , char *argv[] ) {
  std::vector<std::vector<int>> * a = new std::vector<std::vector<int>> ;
  * a = { { 1 , 2 } , { 3 , 4 } } ;
  ka23::print ( ka23::toString ( 1 ) ) ;
  delete a ;
}
