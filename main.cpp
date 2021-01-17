#include "ka2lib/ka2funcs.cpp"

int main ( int argc , char *argv[] ) {
  std::vector<int> hairetsu = ( std::vector<int> ) { 1 , 2 , 3 } ;
  ka23::println ( ka23::toString ( ka23::last ( ka23::map ( ( std::vector<int> ) { 1 , 2 , 3 } , [] ( int _i ) { return ka23::plus ( _i , 1 ) ; } ) ) ) ) ;
  ka23::println ( ka23::toString ( ka23::last ( ka23::join ( ( std::vector<int> ) { 1 , 2 , 3 } , ( std::vector<int> ) { 4 , 5 , 6 } ) ) ) ) ;
  ka23::println ( ka23::toString ( ka23::last ( ka23::tail ( ( std::vector<int> ) { 1 , 2 , 3 } ) ) ) ) ;
  ka23::println ( ka23::toString ( ka23::last ( ka23::init ( ( std::vector<int> ) { 1 , 2 , 3 } ) ) ) ) ;
  ka23::println ( ka23::toString ( ka23::len ( ( std::vector<int> ) { 1 , 2 , 3 } ) ) ) ;
}
