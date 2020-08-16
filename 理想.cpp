#include<stdio.h>
#include "ka2calc.h"

int main() {
  auto tasuyo = [] ( int x ) {
    return [x] ( int y ) {
      return ( k_add ( x ) ( y ) );
    };
  };
  int a = tasuyo ( 1 ) ( 4 ) ;
  if ( k_eq ( a ) ( 5 ) ) {
    printf ( "10" ) ;
    printf ( "はお" ) ;
  } else {
    printf ( "100" ) ;
  }
}