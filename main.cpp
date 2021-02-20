#include "gridfuncs.cpp"
#include <chrono>

std::vector<int> sort ( std::vector<int> a ) {
  if ( ( grid::len ( a ) <= 1 ) ) {
    return ( a ) ;
  }
  else {
    int pivot = a [ 0 ] ;
    std::vector<int> left = grid::filter ( grid::tail ( a ) , [=] ( int _i ) { return ( _i < pivot ) ; } ) ;
    std::vector<int> right = grid::filter ( grid::tail ( a ) , [=] ( int _i ) { return ( _i >= pivot ) ; } ) ;
    return ( grid::join ( grid::join ( sort ( left ) , ( std::vector<int> ) { pivot } ) , sort ( right ) ) ) ;
  }
  return ( std::vector<int> ) {} ;
}

int main ( int argc , char *argv[] ) {
  double heikin = 0.0;

  for(int i = 0; i < 1; i++){
    std::chrono::system_clock::time_point  start, end; // 型は auto で可
    start = std::chrono::system_clock::now(); // 計測開始時間
    
    for(int i = 0; i < 100000; i++){
      sort ( ( std::vector<int> ) { 1 , 3 , 45 , 27 , 7 , 10 , 1 , 1 , 5 , 2 , 4 , 9 , 2 , 6 , 13 , 12 } ) ;
    }
    
    end = std::chrono::system_clock::now();  // 計測終了時間
    double elapsed = std::chrono::duration_cast<std::chrono::microseconds>(end-start).count();
    if(heikin == 0.0) {
      heikin = elapsed;
    } else {
      heikin = (heikin + elapsed) / 2;
    }
  }

  grid::println(grid::toString(/1000000) + "秒");
}
