#include <iostream>
#include <string>
#include <vector>
#include <tuple>
#include <functional>

namespace grid {
  auto plus = [](auto a, auto b){
    return a + b;
  };

  auto minu = [](auto a, auto b){
    return a - b;
  };

  auto mult = [](auto a, auto b){
    return a * b;
  };

  auto divi = [](auto a, auto b){
    return a / b;
  };

  auto lt = [](auto a, auto b){
    return a < b;
  };

  auto gt = [](auto a, auto b){
    return a > b;
  };

  auto le = [](auto a, auto b){
    return a <= b;
  };

  auto ge = [](auto a, auto b){
    return a >= b;
  };

  auto ee = [](auto a, auto b){
    return a == b;
  };

  // ne関数
  auto ne = [](auto a, auto b){
    return a != b;
  };

  auto len = [](auto a) -> int {
    return (int)a.size();
  };

  auto join = [](auto a, auto b) {
    decltype(a) c;
    c.reserve(a.size() + b.size());
    c.insert(c.end(), a.begin(), a.end());
    c.insert(c.end(), b.begin(), b.end());
    return c;
  };

  auto head = [](auto a) {
    return a[0];
  };

  auto tail = [](auto a) {
    decltype(a) b(a.size()-1);
    copy(a.begin()+1, a.end(), b.begin());
    return b;
  };

  auto last = [](auto a) {
    return a.back();
  };

  auto init = [](auto a) {
    decltype(a) b(a.size()-1);
    copy(a.begin(), a.end()-1, b.begin());
    return b;
  };

  auto at = [](auto a, auto b) {
    return a[b];
  };

  auto map = [](auto a, auto b) {
    decltype(a) c = {};
    for(auto d : a) {
      c.push_back(b(d));
    }
    return c;
  };

  auto print = [](auto a){
    std::cout << a;
  };

  auto toString = [](auto a){
    std::string b = std::to_string(a);
    return b;
  };

  auto println = [](auto a){
    std::cout << a << "\n";
  };

  auto readln = [](){
    std::string a = "";
    std::cin >> a;
    return a;
  };

}