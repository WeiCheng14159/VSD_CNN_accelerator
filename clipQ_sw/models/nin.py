import torch.nn as nn
import torch
import torch.nn.functional as F
import os
from Qfile import fileW2, fileW8, fileW32
from ch_Qfile import ch_fileW2, ch_fileW8, ch_fileW32, out_ch_fileW8
import numpy


class NbitActive(torch.autograd.Function):
    '''
    N bit quantize the input activations
    '''
    @staticmethod
    def forward(ctx, input):
        ctx.save_for_backward(input)
        outp = input.clone()
        num_bits = 8
        num_int = 3
        qmin = -(2.**(num_int - 1))
        qmax = qmin + 2.**num_int - 1./(2.**(num_bits - num_int))
        scale = 1/(2.**(num_bits - num_int))
        output = outp - torch.fmod(outp, scale)
        output[output.le(qmin)] = qmin
        output[output.ge(qmax)] = qmax
        return output

    @staticmethod
    def backward(ctx, grad_output):
        input = ctx.saved_tensors
        num_bits = 8
        num_int = 3
        qmin = -(2.**(num_int - 1))
        qmax = qmin + 2.**num_int - 1./(2.**(num_bits - num_int))
        grad_input = grad_output.clone()
        grad_input[input[0].le(qmin)] = 0
        grad_input[input[0].ge(qmax)] = 0

        return grad_input


class QConv2d(nn.Module):
    def __init__(self, input_channels, output_channels,
                 kernel_size=-1, stride=-1, padding=-1, dropout=0, layer=0, full=0, w=False):
        super(QConv2d, self).__init__()
        self.layer_type = 'QConv2d'
        self.kernel_size = kernel_size
        self.stride = stride
        self.padding = padding
        self.dropout_ratio = dropout
        self.layer = layer
        self.full = full
        self.bn = nn.BatchNorm2d(
            input_channels, eps=1e-4, momentum=0.1, affine=True)
        self.bn.weight.data = self.bn.weight.data.zero_().add(1.0)
        self.w = w
        if dropout != 0:
            self.dropout = nn.Dropout(dropout)
        self.conv = nn.Conv2d(input_channels, output_channels,
                              kernel_size=kernel_size, stride=stride, padding=padding)
        self.relu = nn.ReLU(inplace=True)

    def forward(self, x):
        # x = self.bn(x)

        if self.full == 0:
            x = NbitActive.apply(x)

        if self.w:
            # for write input.hex
            if not os.path.exists('./H_data/conv{:d}/In8.hex'.format(int(self.layer)-1)):
                ch_fileW8(x[0], './H_data/conv{:d}/In8.hex'.format(int(self.layer)-1), 5)

        if self.dropout_ratio != 0:
            x = self.dropout(x)

        x = self.conv(x)

        if self.w:
            # for write bias.hex
            if not os.path.exists('./H_data/conv{:d}/Bias32.hex'.format(int(self.layer)-1)):
                fileW32(self.conv.bias.data, './H_data/conv{:d}/Bias32.hex'.format(int(self.layer)-1), 10)

        x = self.relu(x)

        if self.w:
            # for write output.hex
            if not os.path.exists('./H_data/conv{:d}/Out8.hex'.format(int(self.layer)-1)):
                out_ch_fileW8(x[0], './H_data/conv{:d}/Out8.hex'.format(int(self.layer)-1), 5)

        return x


class QMaxPool2d(nn.Module):
    def __init__(self, kernel_size=-1, stride=-1,padding=-1, layer=0, w=False):
        super(QMaxPool2d, self).__init__()

        self.kernel_size = kernel_size
        self.layer = layer
        self.w = w
        self.MaxPool = nn.MaxPool2d(kernel_size=kernel_size, stride=stride, padding=padding)

    def forward(self, x):
        if self.w:
            # for write input.hex
            if not os.path.exists('./H_data/pool{:d}/In8.hex'.format(int(self.layer))):
                out_ch_fileW8(x[0], './H_data/pool{:d}/In8.hex'.format(int(self.layer)), 5)

        x = self.MaxPool(x)

        if self.w:
            # for write Output.hex
            if not os.path.exists('./H_data/pool{:d}/Out8.hex'.format(int(self.layer))):
                out_ch_fileW8(x[0], './H_data/pool{:d}/Out8.hex'.format(int(self.layer)), 5)
        return x


class Net(nn.Module):
    def __init__(self, f, cifar, write):
        super(Net, self).__init__()
        self.QCNN = nn.Sequential(
            QConv2d(3,  96, kernel_size=3, stride=1,
                    padding=1, layer=1, full=f, w=write),
            QConv2d(96, 160, kernel_size=1, stride=1,
                    padding=0, layer=2, full=f, w=write),
            QConv2d(160, 192, kernel_size=1, stride=1,
                    padding=0, layer=3, full=f, w=write),
            # nn.MaxPool2d(kernel_size=2, stride=2, padding=0),
            QMaxPool2d(kernel_size=2, stride=2,
                    padding=0, layer=0, w=write),

            QConv2d(192, 96, kernel_size=3, stride=1,
                    padding=1, layer=4, full=f, w=write),
            QConv2d(96, 192, kernel_size=1, stride=1,
                    padding=0, layer=5, full=f, w=write),
            QConv2d(192, 192, kernel_size=1, stride=1,
                    padding=0, layer=6, full=f, w=write),
            # nn.AvgPool2d(kernel_size=2, stride=2, padding=0),
            # nn.MaxPool2d(kernel_size=2, stride=2, padding=0),
            QMaxPool2d(kernel_size=2, stride=2,
                    padding=0, layer=1, w=write),

            QConv2d(192, 384, kernel_size=3, stride=1,
                    padding=1, layer=7, full=f, w=write),
            QConv2d(384, 192, kernel_size=1, stride=1,
                    padding=0, layer=8, full=f, w=write),
            QConv2d(192, int(cifar), kernel_size=1,
                    stride=1, padding=0, layer=9, full=f, w=write),
            # nn.AvgPool2d(kernel_size=8, stride=1, padding=0),
            # nn.MaxPool2d(kernel_size=8, stride=1, padding=0),
            QMaxPool2d(kernel_size=8, stride=1,
                    padding=0, layer=2, w=write),
        )

    def forward(self, x):
        for m in self.modules():
            if isinstance(m, nn.BatchNorm2d) or isinstance(m, nn.BatchNorm1d):
                if hasattr(m.weight, 'data'):
                    m.weight.data.clamp_(min=0.01)
        x = self.QCNN(x)
        x = x.view(x.size(0), -1)
        return x
