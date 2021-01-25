#include "gridfuncs.cpp"

int FizzBuzz ( int num ) {
  if ( ( ( ( num / 15 ) * 15 ) == num ) ) {
    grid::println ( ( std::string ) "FizzBuzz" ) ;
  }
  else if ( ( ( ( num / 5 ) * 5 ) == num ) ) {
    grid::println ( ( std::string ) "Buzz" ) ;
  }
  else if ( ( ( ( num / 3 ) * 3 ) == num ) ) {
    grid::println ( ( std::string ) "Fizz" ) ;
  }
  else {
    grid::println ( grid::toString ( num ) ) ;
  }
  return ( num ) ;
}

int main ( int argc , char *argv[] ) {
  grid::map ( grid::range ( 1 , 50 ) , [=] ( int _i ) { return FizzBuzz ( _i ) ; } ) ;
}
