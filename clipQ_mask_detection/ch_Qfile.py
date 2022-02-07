
from __future__ import print_function
import torch
import math as m
import numpy as np
import time
import os

# for debug
import ipdb

os.environ["CUDA_VISIBLE_DEVICES"] = "1"


# def ch_fileW8(input, name, frag_bit):
#     x = input.clone().cpu()
#     k = x.transpose(1, 0).transpose(2, 1)
#     if(k.size(2) % 4 != 0):
#         ze = torch.zeros(k.size(0), k.size(1), 4-k.size(2) % 4)
#         k = torch.cat((k, ze), 2)
#     data = k.contiguous().view(-1).detach().numpy()
#     data = data*(2.**frag_bit)
#     for i in range(len(data)):
#         data[i] = int(data[i])
#         if data[i] < 0:
#             data[i] += 256
#     out = []
#     for i in range(len(data)):
#         out.append(hex(int(data[i])))
#     f = open(name, 'w')
#     for i in range(int(len(data)/4)):
#         f.write('{:02X}{:02X}{:02X}{:02X}\n'.format(
#             int(data[4*i]), int(data[4*i+1]), int(data[4*i+2]), int(data[4*i+3])))
#     if len(data) % 4 == 1:
#         f.write('{:02X}{:02X}{:02X}{:02X}\n'.format(
#             int(data[len(data)-1]), 0, 0, 0))
#     elif len(data) % 4 == 2:
#         f.write('{:02X}{:02X}{:02X}{:02X}\n'.format(
#             int(data[len(data)-2]), int(data[len(data)-1]), 0, 0))
#     elif len(data) % 4 == 3:
#         f.write('{:02X}{:02X}{:02X}{:02X}\n'.format(
#             int(data[len(data)-3]), int(data[len(data)-2]), int(data[len(data)-1]), 0))
#     f.close()
#     return 0

def ch_fileW8(input, name, frag_bit):
  x = input.clone().cpu()

  data = x.contiguous().view(-1).detach().numpy()
  data = data*(2.**frag_bit)
  for i in range(len(data)):
    data[i] = int(data[i])
    if data[i] < 0:
      data[i] += 256

  f = open(name,'w')
  for i in range(int(len(data))):
    f.write('{:02X}\n'.format(int(data[i])))
  f.close()

  return 0

def ch_fileW32(input, name, frag_bit):
    x = input.clone().cpu()
    k = x.transpose(1, 0).transpose(2, 1)
    if(k.size(2) % 4 != 0):
        ze = torch.zeros(k.size(0), k.size(1), 4-k.size(2) % 4)
        k = torch.cat((k, ze), 2)
    data = k.view(-1).detach().numpy()
    data = data*(2.**frag_bit)
    f = open(name, 'w')
    for i in range(int(len(data))):
        if data[i] < 0:
            data[i] = data[i] + 2**20
            if ('{:05X}'.format(int(data[i]))) == '100000':
                f.write('00000000\n')
            else:
                f.write('FFF{:05X}\n'.format(int(data[i])))
        else:
            f.write('{:08X}\n'.format(int(data[i])))
    f.close()

    return 0


def ch_fileW2(input, name):
    x = input.clone().cpu()
    k = x.transpose(2, 0).transpose(3, 1)
    if(k.size(3) % 4 != 0):
        ze = torch.zeros(k.size(0), k.size(1), k.size(2), 4-k.size(3) % 4)
        k = torch.cat((k, ze), 3)
    k = k.view([-1, k.size(2), k.size(3)])
    div = int(k.size(2)/4)
    kc = k.view([k.size(0), -1, 4, div, 4])
    kc = kc.transpose(2, 3)
    d = kc.transpose(0, 1).transpose(1, 2)
    data = d.contiguous().view(-1).detach().numpy()
    for i in range(len(data)):
        data[i] = int(data[i])

    if len(data) % 16 != 0:
        for i in range(16 - int(len(data) % 16)):
            data = np.append(data, [0])
    f = open(name, 'w')
    for i in range(int(len(data)/4)):
        num = data[4*i]*64 + data[4*i+1]*16 + data[4*i+2]*4 + data[4*i+3]
        f.write('{:02X}'.format(int(num)))

        if i % 4 == 3:
            f.write('\n')
    f.close()
    return 0

def ch_fileW2_kernel_3x3(input, name):
    x = input.clone().cpu()
    data = x.contiguous().view(-1).detach().numpy()

    cnt = 0
    sum = 0
    f = open(name, 'w')
    for i in range(len(data)):
        sum = sum + (int(data[i]) << (2*cnt))

        if cnt == 8:
            f.write('{:05X}'.format(int(sum)))
            f.write('\n')
            cnt = 0
            sum = 0
        else:
            cnt = cnt + 1

    f.close()

    return 0

def ch_fileW2_kernel_1x1(input, name, input_ch):
    x = input.clone().cpu()
    data = x.contiguous().view(-1).detach().numpy()

    cnt = 0
    sum = 0
    f = open(name, 'w')
    for i in range(len(data)):
        sum = sum + (int(data[i]) << (2*cnt))

        if cnt == 8 or (i%input_ch == input_ch-1):
            f.write('{:05X}'.format(int(sum)))
            f.write('\n')
            cnt = 0
            sum = 0
        else:
            cnt = cnt + 1

    f.close()

    return 0

# def out_ch_fileW8(input, name, frag_bit):
#     x = input.clone().cpu()
#     num_bits = 8
#     num_int = 3
#     qmin = -(2.**(num_int - 1))
#     qmax = qmin + 2.**num_int - 1./(2.**(num_bits - num_int))
#     scale = 1/(2.**(num_bits - num_int))
#     x = x - torch.fmod(x, scale)
#     x[x.le(qmin)] = qmin
#     x[x.ge(qmax)] = qmax

#     k = x.transpose(1, 0).transpose(2, 1)
#     if(k.size(2) % 4 != 0):
#         ze = torch.zeros(k.size(0), k.size(1), 4-k.size(2) % 4)
#         k = torch.cat((k, ze), 2)
#     data = k.contiguous().view(-1).detach().numpy()
#     data = data*(2.**frag_bit)
#     for i in range(len(data)):
#         data[i] = int(data[i])
#         if data[i] < 0:
#             data[i] += 256
#     out = []
#     for i in range(len(data)):
#         out.append(hex(int(data[i])))
#     f = open(name, 'w')
#     for i in range(int(len(data)/4)):
#         f.write('{:02X}{:02X}{:02X}{:02X}\n'.format(
#             int(data[4*i]), int(data[4*i+1]), int(data[4*i+2]), int(data[4*i+3])))
#     if len(data) % 4 == 1:
#         f.write('{:02X}{:02X}{:02X}{:02X}\n'.format(
#             int(data[len(data)-1]), 0, 0, 0))
#     elif len(data) % 4 == 2:
#         f.write('{:02X}{:02X}{:02X}{:02X}\n'.format(
#             int(data[len(data)-2]), int(data[len(data)-1]), 0, 0))
#     elif len(data) % 4 == 3:
#         f.write('{:02X}{:02X}{:02X}{:02X}\n'.format(
#             int(data[len(data)-3]), int(data[len(data)-2]), int(data[len(data)-1]), 0))
#     f.close()
#     return 0

def out_ch_fileW8(input, name, frag_bit):
  x = input.clone().cpu()
  num_bits = 8
  num_int = 3
  qmin = -(2.**(num_int - 1))
  qmax = qmin + 2.**num_int - 1./(2.**(num_bits - num_int))
  scale = 1/(2.**(num_bits - num_int))
  x = x - torch.fmod(x,scale)
  x[x.le(qmin)] = qmin
  x[x.ge(qmax)] = qmax

  data = x.contiguous().view(-1).detach().numpy()
  data = data*(2.**frag_bit)
  for i in range(len(data)):
    data[i] = int(data[i])
    if data[i] < 0:
      data[i] += 256

  f = open(name,'w')
  for i in range(int(len(data))):
    f.write('{:02X}\n'.format(int(data[i])))
  f.close()

  return 0


'''
a = torch.rand(10,10)*4
x = a.clone().view(-1).numpy()

out2=[]
for i in range(len(x)):
  x[i]= int(x[i])
print(x)


if len(x)%16!=0:
  for i in range(16 - int(len(x)%16)):
    x=np.append(x,[0])
print(x)


for i in range(int(len(x)/4)): 
  num = x[4*i]*64 + x[4*i+1]*16 + x[4*i+2]*4 + x[4*i+3]
  if i%4==0:
    print('0x',end = '')
  print('{:02X}'.format(int(num)),end = '')
  
  if i%4==3:
    print()
if not os.path.exists('Q2.hex'):
  fileW2(a,'Q2.hex')
'''

# f.close()
'''
print(x.ge(0))
print(x.le(3))
print(x[x.ge(0)*x.le(3)])

num_bits = 8
mmin = x.min()
mmax = x.max()
mrange = mmax - mmin
qmin = -(2.**(num_bits - 1))
qmax = qmin + 2.**num_bits - 1.
#scale = qparams.range / (qmax - qmin)
print(mmin)
scale = mrange / (qmax - qmin)
x.add_(qmin * scale - mmin).div_(scale)
print(x)
x.clamp_(qmin, qmax).round_()

print(x)

grad_input = a.clone()

grad_input[a.le(mmin - 1)] = 0
grad_input[a.ge(mmax + 1)] = 0
print(scale)
for i in range(int(2**num_bits - 1)):
  grad_input[a.ge(mmin + 0.1 + i*scale)*a.le(mmin -0.1 + (i+1)*scale)] = 0


print(grad_input)
'''
