#include "gridfuncs.cpp"

int main ( int argc , char *argv[] ) {
  grid::println ( grid::boolToString ( grid::nequal ( ( std::vector<int> ) { 1 , 2 } , ( std::vector<int> ) { 2 , 2 } ) ) ) ;
  grid::println ( grid::boolToString ( ( ( std::vector<int> ) { 1 , 2 } == ( std::vector<int> ) { 1 , 2 } ) ) ) ;
  grid::equal ( ( std::vector<int> ) { 1 , 2 } , ( std::vector<int> ) { 1 , 2 } ) ;
}
