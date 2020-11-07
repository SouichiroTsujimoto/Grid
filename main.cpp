#include <iostream>
#include <algorithm>
#include "ka2lib/ka2funcs.h"

const std::vector<int> x = { 1 } ;
int main ( int argc , char *argv[] ) {
  ka23::print ( ka23::head ( ka23::tail ( x ) ) ) ;
  ka23::print ( ka23::last ( ka23::tail ( x ) ) ) ;
  ka23::print ( ka23::head ( ka23::init ( x ) ) ) ;
  ka23::print ( ka23::last ( ka23::init ( x ) ) ) ;
}
