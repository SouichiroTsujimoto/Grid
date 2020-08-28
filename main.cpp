#include "ka2lib/ka2calc.h"
#include "ka2lib/ka2IO.h"

int main() {
  auto x = [] ( int y ) {
    const int a = 10 ;
    const int b = 100 ;
    return ( k_add ( k_mul ( a ) ( b ) ) ( y ) ) ;
  } ;
    const std::string x = "XXX" ;
  
}