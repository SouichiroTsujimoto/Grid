#include "ka2lib/ka2funcs.h"

int main ( int argc , char *argv[] ) {
  std::string * a = new std::string ;
  * a = ka23::toString ( 10 ) ;
  delete a ;
  std::string * a = new std::string ;
  * a = "aaaaa" ;
  ka23::print ( * a ) ;
  delete a ;
}
