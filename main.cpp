#include "ka2lib/ka2funcs.h"

int main ( int argc , char *argv[] ) {
  const std::vector<std::vector<bool>> a = ( std::vector<std::vector<bool>> ) { ( std::vector<bool> ) { true , false , false } , ( std::vector<bool> ) { true , false , false } } ;
  ka23::println ( ka23::toString ( ka23::len ( a ) ) ) ;
}
