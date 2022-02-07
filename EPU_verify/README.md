# EPU verification
This is a stand-alone testbench for EPU that simulates the following processes:
- TB loads input/weight/bias data into RTL-simulated SRAM buffers.
- TB pulls start signal to high
- EPU starts computation and writes results to output buffer.
- EPU pulls finish signal to high
- TB verify the content of output buffer.

## Command (For mask detection NN)
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

## Command (For modified NIN tested on CIFAR-10) 
Change the soft link `data` so that it points to `cifar10_data` folder.
Run the following make targets.
- conv0 (3x3 conv)
  ```bash=1 
  make rtl0
  ```
- conv1 (1x1 conv)
  ```bash=1 
  make rtl1
  ```
- conv2 (1x1 conv)
  ```bash=1 
  make rtl2
  ```
- pool0 (2x2 max pooling)
  ```bash=1 
  make pool0
  ```
- conv3 (3x3 conv)
  ```bash=1 
  make rtl3
  ```
- conv4 (1x1 conv)
  ```bash=1 
  make rtl4
  ```
- conv5 (1x1 conv)
  ```bash=1 
  make rtl5
  ```
- pool1 (2x2 max pooling)
  ```bash=1 
  make pool1
  ```
- conv6 (3x3 conv)
  ```bash=1 
  make rtl6
  ```
- conv7 (1x1 conv)
  ```bash=1 
  make rtl7
  ```
- conv8 (1x1 conv)
  ```bash=1 
  make rtl8
  ```
- pool2 (8x8 max pooling)
  ```bash=1 
  make pool2
  ```