#include "gridfuncs.cpp"

std::vector<int> quicksort ( std::vector<int> arr ) {
  if ( ( grid::len ( arr ) <= 1 ) ) {
    return ( arr ) ;
  }
  int pivot = arr [ ( grid::len ( arr ) / 2 ) ] ;
  std::vector<int> res = ( std::vector<int> ) {} ;
  std::vector<std::vector<int>> fuga = ( std::vector<std::vector<int>> ) {} ;
  fuga = ( std::vector<std::vector<int>> ) { ( std::vector<int> ) { 1 , 2 } } ;
  {
    std::vector<int> middle = ( std::vector<int> ) {} ;
    std::vector<int> left = ( std::vector<int> ) {} ;
    std::vector<int> right = ( std::vector<int> ) {} ;
    for ( int elem : arr ) {
      if ( ( elem == pivot ) ) {
        middle = grid::join ( middle , ( std::vector<int> ) { elem } ) ;
      }
      else if ( ( elem < pivot ) ) {
        left = grid::join ( left , ( std::vector<int> ) { elem } ) ;
      }
      else {
        right = grid::join ( right , ( std::vector<int> ) { elem } ) ;
      }
    }
    grid::join ( grid::join ( res = quicksort ( left ) , middle ) , quicksort ( right ) ) ;
  }
  return ( res ) ;
}

int main ( int argc , char *argv[] ) {
  std::vector<int> res = quicksort ( ( std::vector<int> ) { 4 , 1 , 3 , 1 , 2 , 9 , 1 , 3 , 4 , 6 , 3 , 4 , 2 , 5 , 6 , 4 , 7 , 3 , 8 , 2 } ) ;
  for ( int elem : res ) {
    grid::println ( grid::toString ( elem ) ) ;
  }
}
