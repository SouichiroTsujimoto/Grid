#include "gridfuncs.cpp"

int main ( int argc , char *argv[] ) {
  grid::join ( ( std::vector<int> ) { 1 , 2 } , ( std::vector<int> ) { 2 , 3 } ) ;
  grid::join ( ( std::vector<int> ) { 1 , 2 } , ( std::vector<int> ) { 2 , 3 } ) ;
}
