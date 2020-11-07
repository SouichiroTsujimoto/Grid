#include <iostream>
#include <algorithm>
#include "ka2lib/ka2funcs.h"

const std::vector<int> x = { 1 , 2 , 3 } ;
int main ( int argc , char *argv[] ) {
  ka23::print ( ka23::tail ( x ) [ 0 ] ) ;
}
