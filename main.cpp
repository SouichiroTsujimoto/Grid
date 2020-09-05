#include <vector>
#include "ka2lib/ka2calc.h"
#include "ka2lib/ka2IO.h"

int main() {
  const std::vector<std::string> x = { "Hello" , "World" } ;
  const std::vector<std::vector<int>> a = { { 1 , 2 } , { 1 } } ;
  std::vector<std::vector<int>> b = { { 2 , 5 , 6 } , { 4 , 5 } } ;
  std::vector<std::vector<std::vector<int>>> c = { { { 2 } , { 5 , 6 } } , { { 4 , 1 } , { 5 } } } ;

}