# A complete SW/HW co-design system for mask detection

### VLSI System Design (VSD) 2021 Final Project in NCKU, Tainan
---
## Motivation
Wearing a mask and social distancing were the only measure to deal with COVID-19 before the present of vaccines. Not to mention, the upcoming COVID variant leads to many breakthorugh cases around the world. Wearing a mask seems to be an effective measure against COVID infection. Despite the effectiveness of wearing a mask, enforcing such public health measure on customers is timing consuming for small businesses. Therefore, we promote a solution based on a ASIC CNN accelerator that is capable of monitoring the mask wearing restriction automatically.

## Hardware system architecture
Our mask detection CNN accelerator has the following HW architecture:
![Alt text](./figure/hardware_arch.png?raw=true)
### CPU
- 5-stage pipeline
- Implement 45 RV32I instructions
- Direct mapped L1-I$ and L1-D$
- Partially implement CSR instructions (M-mode only)

### AXI
- Connects 3 master and 7 slaves
- AXI bridge verified by Cadence Assertion-Based Verification IP (ABVIP)

### EPU (Extended Processing Unit)
- 180 KiB weight buffer
- 2 KiB bias buffer
- 384 KiB output buffer
- 384 KiB input buffer
- 3x3/1x1 convolution, max-pooling

### RAM
- 64KB instruction memory (IM)
- 64KB data memory (DM)

### DRAM
- Off-chip memory simulated by testbench
- tPR (Precharge time) = 5
- tRCD (Row Address to Column Address Delay) = 5
- CL (CAS latency) = 5

### ROM
- 16 KB off-chip memory 

## ASIC spec
| | Single clock domain, Speed = 100 MHz, U18 process | |
| -           | -             | -               |
| CPU         | CPU+I$+D$     | ~1mm^2          |
| RAM         | IM (32KB)     | ~2.6 mm^2       |
|             | DM (32KB)     | ~2.6 mm^2       |
| EPU Buffers | Bias buffer   | ~0.3 mm^2       |
|             | Weight Buffer | ~7.8 mm^2       |
|             | Input Buffer  | ~16 mm^2        | 
|             | Output Buffer | ~16 mm^2        |
| EPU         |               | ~0.6 mm^2       |
|             || Total area (SYN) 47.6 mm^2     |
|             || Total area (APR) 67.9 mm^2     |

  ![Alt text](./figure/APR_layout.png?raw=true)

###
## NN quantization & compression
- We use a NIN (Network In Network) model [1] and apply CLIP-Q [2] algorithm to quantize and compress the network.

- NIN architecture in brief:

  - NIN architecture from the original paper which includes the stacking of three mlpconv layers and one global average pooling layer.

  ![Alt text](./figure/NIN_orig_arch.png?raw=true)

- The CLIP-Q algorithm in brief: 

  - CLIP-Q combines weight pruning and quantization in a single learning framework, and performs pruning and quantization in parallel with fine-tuning. The joint runing-quantization adapts over time with the changing network.
  ![Alt text](./figure/CLIP-Q_1.png?raw=true)

  - An example illustrating the three steps of the pruning-quantization operation for a layer with 16 weights, p = 0.25 and b = 2. Pruning-quantization is performed in parallel with fine-tuning the network’s full-precision weights, and updates the pruning statuses, quantization levels, and assignments of weights to quantization levels after each training minibatch.
  ![Alt text](./figure/CLIP-Q_2.png?raw=true)

## NN arhitecture
### NIN NN model
We modified the NIN model by replacing average pooling layer with max pooling and remove batch normalization layer. The modified version of NIN consists of the following layers: 

![Alt text](./figure/NIN_arch.png?raw=true)

We are able to obtain ~82% accuracy with this model on CIFAR-10 dataset while the original NIN model (without quantization and pruning) is capable of reaching 90% accuracy. The possible cause might be the removal of batch normalization layers and the replacement of average pooling layers.

### Mask detection NN model
- We further shrink the NN model for mask detection based on the NIN model, and eventually came up with the following model setup:

![Alt text](./figure/mask_NN_arch.png?raw=true)

We then apply CLIP-Q quantization and pruning algorithm to further compress this model so that it fits in our NN accelerator. Eventually we are able to obtain a ~82% accuracy on our custom mask wearing dataset.

## Slides
More details on our presentation [slides](slides/presentation.pptx) for more details.

## Contribution
Special thanks to [@Wder4](https://github.com/Wder4) [@NCKUMaxSnake](https://github.com/NCKUMaxSnake) [@sam2468sam](https://github.com/sam2468sam) [@alan-chen1412](https://github.com/alan-chen1412) [@hsiehong](https://github.com/hsiehong) [@GuFangYi](https://github.com/GuFangYi) [@WeiCheng14159](https://github.com/WeiCheng14159) for their contribution.
## Reference
- [1] Lin, M., Chen, Q., & Yan, S. (2013). Network in network. arXiv preprint arXiv:1312.4400.
- [2] Tung, F., & Mori, G. (2018). Clip-q: Deep network compression learning by in-parallel pruning-quantization. In Proceedings of the IEEE conference on computer vision and pattern recognition (pp. 7873-7882).