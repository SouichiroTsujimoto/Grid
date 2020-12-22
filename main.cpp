#include "ka2lib/ka2funcs.h"

int main ( int argc , char *argv[] ) {
  ka23::map ( { 1 , 2 , 3 } , [ ] ( int i ) { return ka23::plus ( i , 1 ) ; } ) ;
}
