#include "gridfuncs.cpp"

typedef struct {
  int a ;
  std::string b ;
} hoge ;

int main ( int argc , char *argv[] ) {
  hoge ahoge = ( hoge ) { 100 , "あ" } ;
  grid::println ( ahoge.b ) ;
}
