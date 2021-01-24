#include<iostream>
#include<vector>
#include<chrono>

void sort(std::vector<int> &arr, int left, int right){
  if (right - left <= 1) return;

  int pivot = arr[(left + right)/2];

  int i = left;
  for(int j = left; j < right - 1; ++j){
    if(arr[j] < pivot){ 
      std::swap(arr[i++], arr[j]);
    }
  }
  std::swap(arr[i], arr[right - 1]);

  sort(arr, left, i);
  sort(arr, i+1, right);
}

int main() {
  std::chrono::system_clock::time_point  start, end;
  start = std::chrono::system_clock::now(); // 計測開始時間
  const int N = 1000*100;
  std::vector<int> arr = { 4 , 1 , 3 , 1 , 2 , 9 , 1 , 3 , 4 , 6 , 3 , 4 , 2 , 5 , 6 , 4 , 7 , 3 , 8 , 2 };
  for (int i = 0; i < N; ++i) {
    sort(arr, 0, 20);
  }
  end = std::chrono::system_clock::now();  // 計測終了時間
  double elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(end-start).count();

  std::cout << "--------------" << "\n";
  std::cout << std::to_string(elapsed) << "\n";

  return 0;
}