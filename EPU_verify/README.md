# EPU verification
This is a stand-alone testbench for EPU that simulates the following processes:
- TB loads input/weight/bias data into RTL-simulated SRAM buffers.
- TB pulls start signal to high
- EPU starts computation and writes results to output buffer.
- EPU pulls finish signal to high
- TB verify the content of output buffer.

## Command
Use the following command to test EPU computation on mask detection NN
- conv0 (3x3 conv)
  ```bash=1 
  make rtl0
  ```
- conv1 (1x1 conv)
  ```bash=1 
  make rtl1
  ```
- pool0 (32x32 max pooling)
  ```bash=1 
  make pool0
  ```