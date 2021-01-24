#include "gridfuncs.cpp"

int main ( int argc , char *argv[] ) {
  grid::equal ( ( std::vector<int> ) { 1 , 2 } , ( std::vector<int> ) { 1 , 2 } ) ;
  grid::println ( grid::boolToString ( ( ( std::vector<int> ) { 1 , 2 } == ( std::vector<int> ) { 1 , 2 } ) ) ) ;
}
