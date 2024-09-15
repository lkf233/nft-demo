// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract InsertionSort {
    // 插入排序函数，排序一个整数数组
    function insertionSort(
        int[] memory arr
    ) public pure returns (int[] memory) {
        // 从第二个元素开始（第一个元素默认已排序）
        for (uint i = 1; i < arr.length; i++) {
            int key = arr[i]; // 当前需要插入的元素
            uint j = i - 1;

            // 将当前元素与前面已排序的部分进行比较
            // 如果前面的元素比当前元素大，则将前面的元素往后移动
            while (j >= 0 && arr[j] > key) {
                arr[j + 1] = arr[j]; // 元素后移
                if (j == 0) {
                    break; // 防止 uint 下溢（unsigned 类型）
                }
                j--;
            }
            // 插入当前元素到正确的位置
            arr[j] = key;
        }
        return arr; // 返回排序后的数组
    }
}
