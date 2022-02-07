# Full sys verification
This testbench performs whole system simulation with both EPU and CPU. 

## Program flow
- Assume ALL input/weight/bias data in DRAM.
- CPU runs booting program with DMA.
- Use DMA to move data from DRAM to EPU’s buffer.
- CPU writes to EPU ctrl registers which starts up EPU.
- EPU writes to output buffer as CPU stuck at WFI.
- EPU finishes and send interrupt. CPU continues with ISR.
- CPU writes ctrl signals for next layer.
  - Trigger “In-Output buffer swap”
  - Output of this layer is the input of next layer
- If done, DMA move data from EPU to DRAM.
- TB verify the content of DRAM.

## Command
Use the following command to test EPU computation on mask detection NN
- conv0 (3x3 conv)
  ```bash=1 
  make conv0
  ```
- conv1 (1x1 conv)
  ```bash=1 
  make conv1
  ```
- pool0 (32x32 max pooling)
  ```bash=1 
  make pool0
  ```
- Full simulation that computes all 3 layers above
  ```bash=1 
  make conv_all
  ```