#include "ka2lib/ka2funcs.h"

int main ( int argc , char *argv[] ) {
  std::string * a = new std::string ;
  * a = "Hello" ;
  ka23::print ( * a ) ;
  delete a ;
}
