#include <iostream>
#include <vector>
#include <algorithm>
#include "ka2lib/ka2calc.h"
#include "ka2lib/ka2IO.h"

int main() {
  ( k_eq ( k_add ( 5 ) ( 5 ) ) ( 10 ) ?
    "5 + 5 = 10" 
    : "?" ) ;

}