#include "gridfuncs.cpp"

int main ( int argc , char *argv[] ) {
  std::vector<int> x = ( std::vector<int> ) { 1 , 2 , -3 } ;
  grid::join ( ( std::vector<int> ) { 1000 , 2000 } , x ) ;
}
