#include "ka2lib/ka2funcs.h"

int main ( int argc , char *argv[] ) {
  ka23::map ( ( std::vector<int> ) { 1 , 2 , 3 } , [] ( int _i ) { return ka23::plus ( _i , 1 ) ; } ) ;
}
