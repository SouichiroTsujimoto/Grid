#include<iostream>
#include "ka2calc.h"

int main() {
auto tasuyo = [](int x) {
return [x](int y) {
return(k_add(x)(y));
};
};
tasuyo(1)(4);
}