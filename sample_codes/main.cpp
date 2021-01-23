#include "gridfuncs.cpp"

int main ( int argc , char *argv[] ) {
  grid::map ( grid::join ( ( std::vector<int> ) { 1 } , ( std::vector<int> ) { 2 , 3 } ) , [] ( int _i ) { return grid::plus ( _i , 1 ) ; } ) ;
}
