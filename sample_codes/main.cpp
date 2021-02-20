#include <iostream>
#include <vector>
#include <chrono>

std::vector<int> sort(std::vector<int> arr) {
  if((int)arr.size() <= 1) {
    return arr;
  } else {
    int pivot = arr[0];
    std::vector<int> new_arr;
    new_arr.resize((int)arr.size()-1);
    std::copy(arr.begin()+1, arr.end(), new_arr.begin());

    std::vector<int> left;
    left.reserve((int)arr.size());
    std::vector<int> right;
    left.reserve((int)arr.size());

    for(int i = 0; i < (int)new_arr.size(); i++) {
      if(new_arr[i] < pivot) {
        left.push_back(new_arr[i]);
      } else {
        right.push_back(new_arr[i]);
      }
    }
    
    left = sort(left);
    right = sort(right);
    left.push_back(pivot);
    std::copy(right.begin(), right.end(), std::back_inserter(left));

    return left;
  }
}

int main() {
  double heikin = 0.0;

  // for(int i = 0; i < 100; i++){
    std::chrono::system_clock::time_point  start, end; // 型は auto で可
    start = std::chrono::system_clock::now(); // 計測開始時間
    
    for(int i = 0; i < 100000; i++){
      sort ( ( std::vector<int> ) { 1 , 3 , 45 , 27 , 7 , 10 , 1 , 1 , 5 , 2 , 4 , 9 , 2 , 6 , 13 , 12 } ) ;
    }
    
    end = std::chrono::system_clock::now();  // 計測終了時間
    double elapsed = std::chrono::duration_cast<std::chrono::microseconds>(end-start).count();
    if(heikin == 0.0) {
      heikin = elapsed;
    } else {
      heikin = (heikin + elapsed) / 2;
    }
  // }

  std::cout << std::to_string(heikin/1000000) << "秒" << "\n";
}