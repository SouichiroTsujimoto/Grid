#include "ka2lib/ka2funcs.h"

std::string pnr ( std::string a ) {
  ka23::println ( a ) ;
  return ( a ) ;
}
int main ( int argc , char *argv[] ) {
  ka23::map ( { "あ" , "い" , "う" } , [] ( std::string i ) { return pnr ( i ) ; } ) ;
}
