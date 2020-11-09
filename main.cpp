#include "ka2lib/ka2funcs.h"

int main ( int argc , char *argv[] ) {
  const std::vector<int> x = { 1 , 2 , -3 } ;
  ka23::print ( ka23::init ( x ) [ 0 ] ) ;
}
