#include "ka2lib/ka2funcs.h"

int main ( int argc , char *argv[] ) {
  const std::vector<int> a = ka23::map ( { 1 , 2 , 3 } , [] ( int _i ) { return ka23::mult ( _i , 10 ) ; } ) ;
}
