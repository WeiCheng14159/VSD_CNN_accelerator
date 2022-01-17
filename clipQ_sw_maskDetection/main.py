from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import sys
import torch
import argparse
import util
import util_write
import torch.nn as nn
import torch.optim as optim
import os

from data import get_dataset
from models import nin
from torch.autograd import Variable

# mask detection
from torch.utils.data import random_split
from torchvision.datasets import ImageFolder, DatasetFolder
import torchvision.transforms as transforms



os.environ["CUDA_VISIBLE_DEVICES"] = "1"

def get_class_distribution(dataset_obj):
    count_dict = {k:0 for k,v in dataset_obj.class_to_idx.items()}

    for element in dataset_obj:
        y_lbl = element[1]
        y_lbl = idx2class[y_lbl]
        count_dict[y_lbl] += 1

    return count_dict

def save_state(model, best_acc):
    print('==> Saving model ...')
    state = {
        'best_acc': best_acc,
        'state_dict': model.state_dict(),
    }
    for key in list(state['state_dict'].keys()):
        if 'module' in key:
            state['state_dict'][key.replace('module.', '')] = \
                state['state_dict'].pop(key)
    torch.save(state, 'models/nin_p.pth.tar')


def train(epoch, full):
    model.train()
    for batch_idx, (data, target) in enumerate(trainloader):
        # process the weights including binarization
        if full == 0:
            bin_op.NbitClipQ()

        # forwarding
        data, target = Variable(data.cuda()), Variable(target.cuda())
        optimizer.zero_grad()
        output = model(data)

        # backwarding
        loss = criterion(output, target)
        loss.backward()

        # restore weights
        if full == 0:
            bin_op.restore()

        optimizer.step()
        if batch_idx % 100 == 0:
            print('Train Epoch: {} [{}/{} ({:.0f}%)]\tLoss: {:.6f}\tLR: {}'.format(
                epoch, batch_idx * len(data), len(trainloader.dataset),
                100. * batch_idx / len(trainloader), loss.data.item(),
                optimizer.param_groups[0]['lr']))
    return


def test(full):
    global best_acc
    model.eval()
    test_loss = 0
    correct = 0
    if full == 0:
        bin_op.NbitClipQ()
    for data, target in testloader:
        data, target = Variable(data.cuda()), Variable(target.cuda())

        output = model(data)
        test_loss += criterion(output, target).data.item()
        pred = output.data.max(1, keepdim=True)[1]
        correct += pred.eq(target.data.view_as(pred)).cpu().sum()
    if full == 0:
        bin_op.restore()
    acc = 100. * float(correct) / len(testloader.dataset)

    if acc > best_acc:
        best_acc = acc
        save_state(model, best_acc)

    test_loss /= len(testloader.dataset)
    print('\nTest set: Average loss: {:.4f}, Accuracy: {}/{} ({:.2f}%)'.format(
        test_loss * 128., correct, len(testloader.dataset),
        100. * float(correct) / len(testloader.dataset)))
    print('Best Accuracy: {:.2f}%\n'.format(best_acc))
    return

def predict(full):
    global best_acc
    model.eval()
    correct = 0
    if full == 0:
        bin_op.NbitClipQ()

    withMask_cnt = 0
    withoutMask_cnt = 0

    for data, target in predloader:
        data, target = Variable(data.cuda()), Variable(target.cuda())

        output = model(data)
        pred = output.data.max(1, keepdim=True)[1]

        # print(pred)
        if(pred[0] == 0):
            print("[Result] With mask!")
            withMask_cnt += 1
        else:
            print("[Result] Without mask")
            withoutMask_cnt += 1

        print('WithMask: ', withMask_cnt,', withoutMask_cnt: ', withoutMask_cnt)

    if full == 0:
        bin_op.restore()

    return


def adjust_learning_rate(optimizer, epoch, max):
    e = int(max/5)
    update_list = [e, e*2, e*3, e*4]
    if epoch in update_list:
        for param_group in optimizer.param_groups:
            param_group['lr'] = param_group['lr'] * 0.1
    return


if __name__ == '__main__':
    # prepare the options
    parser = argparse.ArgumentParser()
    parser.add_argument('--cpu', action='store_true',
                        help='set if only CPU is available')
    parser.add_argument('--data', action='store', default='./data/',
                        help='dataset path')
    parser.add_argument('--arch', action='store', default='nin',
                        help='the architecture for the network: nin')
    parser.add_argument('--opt', action='store', default='Adam',
                        help='the optimizer')
    parser.add_argument('--lr', action='store', default='0.1',
                        help='the intial learning rate')
    parser.add_argument('--pretrained', action='store', default=None,
                        help='the path to the pretrained model')
    parser.add_argument('--evaluate', action='store_true',
                        help='evaluate the model')
    parser.add_argument('--full', action='store', default='0',
                        help='full precision or not')
    parser.add_argument('--epoch', action='store', default='300',
                        help='training epoch')
    parser.add_argument('--cifar', action='store', default='100',
                        help='cifar10 or cifar100')
    parser.add_argument('--write', action='store_true',
                        help='write_files')
    parser.add_argument('--predict', action='store_true',
                        help='predict single picture')

    args = parser.parse_args()

    print('==> Options:', args)

    # set the seed
    torch.manual_seed(1)
    torch.cuda.manual_seed(1)

    # prepare the data
    '''
    if not os.path.isfile(args.data+'/train_data'):
        # check the data path
        raise Exception\
                ('Please assign the correct data path with --data <DATA_PATH>')
    '''

    cf = float(args.cifar)

    # load mask dataset
    image_transforms = transforms.Compose(
                   [transforms.Resize((32, 32)),
                    transforms.ToTensor(),
                    transforms.Normalize((0.5, 0.5, 0.5), (0.5, 0.5, 0.5))])

    MAIN = './data_mask'
    dataset = ImageFolder(root = MAIN, transform = image_transforms)

    PRED = './data_predict'
    pred_dataset = ImageFolder(root = PRED, transform = image_transforms)

    # print(dataset)

    dataset.class_to_idx = {'with_mask':1, 'without_mask':0}
    idx2class = {v: k for k, v in dataset.class_to_idx.items()}

    # print("Distribution of classes: \n", get_class_distribution(dataset))

    trainset, testset = random_split(dataset, (4173, 1045))

    trainloader = torch.utils.data.DataLoader(dataset=trainset, shuffle=True, batch_size=16, num_workers=2)
    testloader  = torch.utils.data.DataLoader(dataset=testset, shuffle=False, batch_size=16, num_workers=2)

    predloader  = torch.utils.data.DataLoader(dataset=pred_dataset, shuffle=False, batch_size=1, num_workers=2)

    print("Length of the train_loader:", len(trainloader))
    print("Length of the val_loader:", len(testloader))

    print("Length of the predloader:", len(predloader))

    # trainset = get_dataset('train', cifar=cf)
    # trainloader = torch.utils.data.DataLoader(trainset, batch_size=128,
    #                                           shuffle=True, num_workers=2)

    # testset = get_dataset('val', cifar=cf)
    # testloader = torch.utils.data.DataLoader(testset, batch_size=100,
    #                                          shuffle=False, num_workers=2)

    # define classes
    classes = ('plane', 'car', 'bird', 'cat',
               'deer', 'dog', 'frog', 'horse', 'ship', 'truck')

    # define the model
    full_p = int(args.full)

    print('==> building model', args.arch, '...')
    if args.arch == 'nin':
        model = nin.Net(f=full_p, cifar=cf, write=args.write)
    else:
        raise Exception(args.arch+' is currently not supported')

    best_acc = 0
    # initialize the model
    if not args.pretrained:
        print('==> Initializing model parameters ...')

        for m in model.modules():
            if isinstance(m, nn.Conv2d):
                m.weight.data.normal_(0, 0.05)
                m.bias.data.zero_()
    else:
        print('==> Load pretrained model form', args.pretrained, '...')
        pretrained_model = torch.load(args.pretrained)
        #best_acc = pretrained_model['best_acc']
        model.load_state_dict(pretrained_model['state_dict'])

    if not args.cpu:
        model.cuda()
        model = torch.nn.DataParallel(
            model, device_ids=range(torch.cuda.device_count()))
    print(model)

    # define solver and criterion
    base_lr = float(args.lr)

    param_dict = dict(model.named_parameters())
    params = []

    for key, value in param_dict.items():
        params += [{'params': [value], 'lr': base_lr,
                    'weight_decay':0.00001}]
    if args.opt == 'Adam':
        optimizer = optim.Adam(params, lr=0.10, weight_decay=0.00001)
    else:
        optimizer = optim.SGD(params, lr=0.10, weight_decay=0.00001)
    criterion = nn.CrossEntropyLoss()

    # define the binarization operator
    if args.write and args.evaluate:
        bin_op = util_write.Quantize(model)
    else:
        bin_op = util.Quantize(model)

    # predict single picture
    if args.predict:
        best_acc = pretrained_model['best_acc']
        predict(full_p)
        exit(0)

    # do the evaluation if specified
    if args.evaluate:
        best_acc = pretrained_model['best_acc']
        test(full_p)
        exit(0)

    max_ep = int(args.epoch)
    # start training
    for epoch in range(1, max_ep):
        adjust_learning_rate(optimizer, epoch, max_ep)
        train(epoch, full_p)
        test(full_p)
