
from __future__ import print_function
import torch
import math as m
import numpy as np
import time
import os


os.environ["CUDA_VISIBLE_DEVICES"] = "1"


def fileW8(input, name, frag_bit):
    d = input.clone().cpu()
    data = d.view(-1).detach().numpy()
    data = data*(2.**frag_bit)
    for i in range(len(data)):
        data[i] = int(data[i])
        if data[i] < 0:
            data[i] += 256
    out = []
    for i in range(len(data)):
        out.append(hex(int(data[i])))
    f = open(name, 'w')
    for i in range(int(len(data)/4)):
        f.write('{:02X}{:02X}{:02X}{:02X}\n'.format(
            int(data[4*i]), int(data[4*i+1]), int(data[4*i+2]), int(data[4*i+3])))
    if len(data) % 4 == 1:
        f.write('{:02X}{:02X}{:02X}{:02X}\n'.format(
            int(data[len(data)-1]), 0, 0, 0))
    elif len(data) % 4 == 2:
        f.write('{:02X}{:02X}{:02X}{:02X}\n'.format(
            int(data[len(data)-2]), int(data[len(data)-1]), 0, 0))
    elif len(data) % 4 == 3:
        f.write('{:02X}{:02X}{:02X}{:02X}\n'.format(
            int(data[len(data)-3]), int(data[len(data)-2]), int(data[len(data)-1]), 0))
    f.close()
    return 0


def fileW32(input, name, frag_bit):
    d = input.clone().cpu()
    data = d.view(-1).detach().numpy()
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


def fileW2(input, name):
    d = input.clone().cpu()
    data = d.view(-1).detach().numpy()
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
