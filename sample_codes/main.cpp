#include "gridfuncs.cpp"

int main ( int argc , char *argv[] ) {
  grid::println ( grid::toString ( grid::at ( grid::filter ( ( std::vector<int> ) { 1 , 2 , 3 } , [] ( int _i ) { return ( _i != 2 ) ; } ) , 1 ) ) ) ;
}
