import torch
from torchvision import transforms
from torch.utils.data import Dataset, DataLoader, random_split
import torch.nn as nn
import torch.optim as optim
import cv2
import os
import pandas as pd
from PIL import Image
import matplotlib.pyplot as plt
from sklearn.preprocessing import LabelEncoder
import joblib
from collections import defaultdict
import math
import numpy as np

# YOLOv5 dependencies
from yolov5.models.experimental import attempt_load
from yolov5.utils.augmentations import LoadImages
from yolov5.utils.general import non_max_suppression, scale_coords

class PokemonDataset(Dataset):
    def __init__(self, csv_file, img_dir, transform=None):
        self.card_attrs = pd.read_csv(csv_file)
        self.img_dir = img_dir
        self.transform = transform

        self.id_to_set = {}
        self.sets = []

        for index, row in self.card_attrs.iterrows():
            img_path = os.path.join(img_dir, f"{row['id']}.png")
            if os.path.exists(img_path):
                self.id_to_set[row['id']] = row['set']
                self.sets.append(row['set'])

        # Encode the set names into indices
        self.encoder = LabelEncoder()
        self.encoder.fit(self.sets)

    def __len__(self):
        return len(self.id_to_set)

    def __getitem__(self, idx):
        img_id = list(self.id_to_set.keys())[idx]
        img_name = os.path.join(self.img_dir, f"{img_id}.png")
        image = Image.open(img_name).convert('RGB')
        set_name = self.id_to_set[img_id]

        # Convert set name to a numeric label
        label = self.encoder.transform([set_name])[0]

        if self.transform:
            image = self.transform(image)

        return img_id, image, torch.tensor(label, dtype=torch.long)