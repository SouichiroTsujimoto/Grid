#include "gridfuncs.cpp"

int main ( int argc , char *argv[] ) {
  std::vector<int> a = grid::range ( 1000 , 1002 ) ;
  for ( int x : a ) {
    grid::println ( grid::toString ( x ) ) ;
  }
}
