#include "ka2lib/ka2funcs.cpp"

typedef struct {
  int a ;
  std::string b ;
} hoge ;

int main ( int argc , char *argv[] ) {
  hoge ahoge = ( hoge ) { 100 , "だめ" } ;
  ka23::println ( ahoge.b ) ;
}
