#include "ka2lib.h"

int main() {
  auto FizzBuzz = [] ( int x ) {
    return ( ( k_eq ( k_mul ( k_div ( x ) ( 15 ) ) ( 15 ) ) ( x ) ?
      "FIZZBUZZ"  :
    ( k_eq ( k_mul ( k_div ( x ) ( 5 ) ) ( 5 ) ) ( x ) ?
      "BUZZ"  :
    ( k_eq ( k_mul ( k_div ( x ) ( 3 ) ) ( 3 ) ) ( x ) ?
      "FIZZ"  :
    "OTHER"  ) ) )  ) ;
  } ;
  
}