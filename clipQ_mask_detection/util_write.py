import torch
import torch.nn as nn
import numpy as np
import math as m
import time
from Qfile import fileW8
from ch_Qfile import ch_fileW2, ch_fileW2_kernel_3x3, ch_fileW2_kernel_1x1
import os

# for debug
import ipdb
import sys

class Quantize():
    def __init__(self, model):
        count_targets = 0
        for m in model.modules():
            if isinstance(m, nn.Conv2d) or isinstance(m, nn.Linear):
                count_targets = count_targets + 1

        start_range = 0
        end_range = count_targets-1
        self.bin_range = np.linspace(start_range,
                                     end_range, end_range-start_range+1)\
            .astype('int').tolist()
        self.num_of_params = len(self.bin_range)
        self.saved_params = []
        self.target_params = []
        self.target_modules = []
        index = -1
        for m in model.modules():
            if isinstance(m, nn.Conv2d) or isinstance(m, nn.Linear):
                index = index + 1
                if index in self.bin_range:
                    tmp = m.weight.data.clone()
                    self.saved_params.append(tmp)
                    self.target_modules.append(m.weight)

    def NbitClipQ(self):
        self.save_params()
        self.ClipQ()

    def save_params(self):
        for index in range(self.num_of_params):
            self.saved_params[index].copy_(self.target_modules[index].data)

    def ClipQ(self):
        for index in range(self.num_of_params):
            start = time.time()
            x = self.target_modules[index].data.cpu()
            torch.set_printoptions(threshold=sys.maxsize) # for full print ndarray
            torch.set_printoptions(profile="full")

            p = 0.1
            b = 2
            x1 = x.view(-1).numpy()
            x1s = np.sort(x1, axis=None)
            x1arg = np.argsort(x1, axis=None)
            pos = x1s[np.where(x1s > 0)]
            pos_arg = x1arg[np.where(x1s > 0)]
            neg = x1s[np.where(x1s < 0)]
            neg_arg = x1arg[np.where(x1s < 0)]

            P_Znum = m.ceil(len(pos)*p)
            N_Znum = m.ceil(len(neg)*p)

            P_max = max(pos[:P_Znum])
            N_min = min(neg[-N_Znum:])

            x1[pos_arg[:P_Znum]] = 0
            x1[neg_arg[-N_Znum:]] = 0

            x1s = np.sort(x1, axis=None)
            partb0 = m.pow(2, b-1)-1
            partb1 = m.pow(2, b-1)

            pos = x1s[np.where(x1s > 0)]
            neg = x1s[np.where(x1s < 0)]

            pos_s = (pos[len(pos)-1] - P_max)/partb0
            neg_s = (neg[0] - N_min)/partb1

            pos = pos - P_max

            neg = neg - N_min

            pos_d = {}
            neg_d = {}

            sum_pos = np.zeros(int(partb0))
            sum_neg = np.zeros(int(partb1))

            num_pos = np.zeros(int(partb0))
            num_neg = np.zeros(int(partb1))

            pos_max = np.zeros(int(partb0))
            neg_min = np.zeros(int(partb1))

            for i in range(int(partb0)):
                pos_d[i] = pos[np.where(np.floor(pos/pos_s) == i)] + P_max

            try:
                pos_d[partb0-1] = np.append(pos_d[partb0-1],
                                            [pos[len(pos)-1] + P_max])
            except:
                pos_d[partb0-1] = [pos[len(pos)-1] + P_max]

            for i in range(int(partb1)):
                neg_d[i] = neg[np.where(np.floor(neg/neg_s) == i)] + N_min

            try:
                neg_d[partb1-1] = np.append(neg_d[partb1-1], [neg[0] + N_min])
            except:
                neg_d[partb1-1] = [neg[0] + N_min]

            pos_avg = {}
            neg_avg = {}

            for i in pos_d.items():
                pos_avg[i[0]] = sum(i[1])/(len(i[1])+0.0000001)
                try:
                    pos_max[i[0]] = max(i[1])
                except:
                    pass

            for i in neg_d.items():
                neg_avg[i[0]] = sum(i[1])/(len(i[1])+0.0000001)
                try:
                    neg_min[i[0]] = min(i[1])
                except:
                    pass

            xx1 = x1.copy()
            we = x1.copy()
            realW = []

            for i in range(int(partb0)):
                realW.append(pos_avg[i])
                if i == 0:
                    x1[np.logical_and(xx1 > 0, xx1 <= pos_max[i])] = pos_avg[i]
                    we[np.logical_and(xx1 > 0, xx1 <= pos_max[i])] = 1
                else:
                    x1[np.logical_and(xx1 > pos_max[i-1],
                                      xx1 <= pos_max[i])] = pos_avg[i]
                    we[np.logical_and(xx1 > pos_max[i-1],
                                      xx1 <= pos_max[i])] = i+1

            for i in range(int(partb1)):
                realW.append(neg_avg[i])
                if i == 0:
                    x1[np.logical_and(xx1 < 0, xx1 >= neg_min[i])] = neg_avg[i]
                    we[np.logical_and(xx1 < 0, xx1 >= neg_min[i])] = -1
                else:
                    x1[np.logical_and(xx1 < neg_min[i-1],
                                      xx1 >= neg_min[i])] = neg_avg[i]
                    we[np.logical_and(xx1 < neg_min[i-1],
                                      xx1 >= neg_min[i])] = -i-1

            x2 = torch.from_numpy(x1)
            pa = torch.Tensor(realW)
            x = x2.view(x.size())
            num_bits = 8
            num_int = 3
            qmin = -(2.**(num_int - 1))
            qmax = qmin + 2.**num_int - 1./(2.**(num_bits - num_int))
            scale = 1/(2.**(num_bits - num_int))
            xx = x - torch.fmod(x, scale)
            pa = pa - torch.fmod(pa, scale)
            xx[xx.le(qmin)] = qmin
            xx[xx.ge(qmax)] = qmax
            pa[pa.le(qmin)] = qmin
            pa[pa.ge(qmax)] = qmax

            ww = torch.from_numpy(we)
            # for Daniel index
            # ww = ww.view(x.size())+2

            # Max add for CLIPQ index
            ww[ww == 1] = 3
            ww[ww == -1] = 2
            ww[ww == -2] = 1

            # print(ww.view(x.size()))
            # ipdb.set_trace()

            # Max modified for generate mutiple layer data
            if index == 0:
                if not os.path.exists('./H_data/conv{:d}/W2.hex'.format(int(index))):
                    ch_fileW2_kernel_3x3(ww, './H_data/conv{:d}/W2.hex'.format(int(index)))

            if index == 1:
                if not os.path.exists('./H_data/conv{:d}/W2.hex'.format(int(index))):
                    ch_fileW2_kernel_1x1(ww, './H_data/conv{:d}/W2.hex'.format(int(index)), 60)

            if not os.path.exists('./H_data/conv{:d}/W8.hex'.format(int(index))):
                fileW8(pa, './H_data/conv{:d}/W8.hex'.format(int(index)), 5)

            self.target_modules[index].data = xx.cuda()

    def restore(self):
        for index in range(self.num_of_params):
            self.target_modules[index].data.copy_(self.saved_params[index])
