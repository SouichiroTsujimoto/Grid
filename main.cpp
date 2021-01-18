#include "ka2lib/ka2funcs.cpp"

bool FizzBuzz ( std::vector<int> x ) {
  for ( int i : x ) {
    if ( ( ( ( i / 15 ) * 15 ) == i ) ) {
      ka23::println ( "FizzBuzz" ) ;
    }
    else if ( ( ( ( i / 5 ) * 5 ) == i ) ) {
      ka23::println ( "Buzz" ) ;
    }
    else if ( ( ( ( i / 3 ) * 3 ) == i ) ) {
      ka23::println ( "Fizz" ) ;
    }
    else {
      ka23::println ( ka23::toString ( i ) ) ;
    }
  }
  return ( true ) ;
}
int main ( int argc , char *argv[] ) {
  FizzBuzz ( ( std::vector<int> ) { 1 , 2 , 3 , 4 , 5 , 6 , 7 , 8 , 9 , 10 , 11 , 12 , 13 , 14 , 15 } ) ;
  int z = 0 ;
  z = 20 ;
z }
