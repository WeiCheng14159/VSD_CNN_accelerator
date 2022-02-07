import os
import torch
#import _pickle as pickle
import numpy
import torchvision.transforms as transforms
import torchvision.datasets as datasets

__DATASETS_DEFAULT_PATH = './data'


def get_dataset(split='train', cifar=100, transform=transforms.Compose([
    transforms.RandomHorizontalFlip(),
    transforms.RandomCrop(32, 4),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406],
                         std=[0.229, 0.224, 0.225]),
]),
        target_transform=None, download=True, datasets_path=__DATASETS_DEFAULT_PATH):
    train = (split == 'train')
    if cifar == 100:
        root = os.path.join(datasets_path, "cifar100")
        return datasets.CIFAR100(root=root,
                                 train=train,
                                 transform=transform,
                                 target_transform=target_transform,
                                 download=download)
    else:
        root = os.path.join(datasets_path, "cifar10")
        return datasets.CIFAR10(root=root,
                                train=train,
                                transform=transform,
                                target_transform=target_transform,
                                download=download)
