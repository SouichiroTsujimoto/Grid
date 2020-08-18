#include<iostream>
#include<stdio.h>
#include "ka2calc.h"

int main() {
  int a = ( k_gt ( 10 ) ( 5 ) ?
    10  :
  ( k_lt ( 10 ) ( 5 ) ?
    20  :
  ( k_eq ( 10 ) ( 5 ) ?
    100  :
  30  ) ) ) ;
  
}