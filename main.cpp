#include <algorithm>
#include "ka2lib/ka2funcs.h"

int main() {

  auto a = [] ( int b ) {

    return [b] ( int c ) {
      return ( ( b / c ) ) ;
    }    ;
  }  ;
  ka23::print ( a ( 4 , 2 ) ) ;

}