import os
import numpy as np
import pandas as pd
import torch
import torch.nn as nn
from torchvision import transforms
from torch.utils.data import Dataset, DataLoader, random_split
from skimage import io
import matplotlib.pyplot as plt
import torch.nn.functional as F
from torchvision.models import resnet50
from PIL import Image
from sklearn.preprocessing import LabelEncoder

def load_labels(label_path):
    return pd.read_csv(label_path)

def filter_labels(df_label, images_path):
    image_files = [f for f in os.listdir(images_path) if f.endswith('.jpg')]
    label_filtered = []
    for index, row in df_label.iterrows():
        image_name = row['name']
        image_id = '_'.join(row['id'].split('-')[::-1])
        image_file_name = f'{image_name}_{image_id}.jpg'
        if image_file_name in image_files:
            row['image_path'] = image_file_name
            label_filtered.append(row)
    return pd.DataFrame(label_filtered)

def preprocess_labels(df_label_filtered):
    df_clean = df_label_filtered.dropna(subset=['weaknesses'])
    df_clean['weakness_type'] = df_clean['weaknesses'].apply(lambda x: x.split('\'')[3] if pd.notnull(x) else x)
    label_encoder = LabelEncoder()
    integer_encoded = label_encoder.fit_transform(df_clean['weakness_type'])
    n_classes = max(integer_encoded) + 1
    integer_encoded = torch.tensor(integer_encoded, dtype=torch.int64)
    label_onehot = F.one_hot(integer_encoded, num_classes=n_classes)
    return df_clean, label_onehot, n_classes

class MultiLabelDataset(Dataset):
    def __init__(self, df_data, labels, transform=None):
        self.transform = transform
        self.image_paths = list(df_data['image_path'])
        self.labels = labels.float()

    def __len__(self):
        return len(self.image_paths)

    def __getitem__(self, idx):
        img_path = f'./images/{self.image_paths[idx]}'
        image = io.imread(img_path)
        if self.transform:
            image = self.transform(image)
        label = torch.FloatTensor(self.labels[idx])
        return image, label

def crop(image):
    width, height = image.size
    new_width = width // 2
    new_height = height // 4
    left = 0
    top = height - new_height
    right = new_width
    bottom = height
    return image.crop((left, top, right, bottom))

def create_transforms():
    return transforms.Compose([
        transforms.ToPILImage(),
        transforms.Resize((342, 245)),
        transforms.Lambda(lambda x: x.convert('RGB')),
        transforms.Lambda(crop),
        transforms.ToTensor()
    ])

def split_dataset(dataset, train_ratio=0.7, val_ratio=0.15):
    dataset_size = len(dataset)
    train_size = int(train_ratio * dataset_size)
    val_size = int(val_ratio * dataset_size)
    test_size = dataset_size - train_size - val_size
    return random_split(dataset, [train_size, val_size, test_size])

def create_dataloaders(train_dataset, val_dataset, test_dataset, batch_size=64):
    train_dataloader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    val_dataloader = DataLoader(val_dataset, batch_size=batch_size, shuffle=False)
    test_dataloader = DataLoader(test_dataset, batch_size=batch_size, shuffle=False)
    return train_dataloader, val_dataloader, test_dataloader

def initialize_model(n_classes, device):
    model_resnet = resnet50(pretrained=True)
    num_features = model_resnet.fc.in_features
    model_resnet.fc = nn.Linear(num_features, n_classes)
    return model_resnet.to(device)

def train_model(model, train_dataloader, num_epochs, device, optimizer, loss_fn):
    train_history = {"train": [], "acc": []}
    for epoch in range(num_epochs):
        model.train()
        total_loss = 0.0
        num_correct = 0
        for batch in train_dataloader:
            inputs, targets = batch
            inputs, targets = inputs.to(device), targets.to(device)
            optimizer.zero_grad()
            outputs = model(inputs)
            loss = loss_fn(outputs, targets)
            loss.backward()
            optimizer.step()
            torch.cuda.empty_cache()
            total_loss += loss.item()
            _, predicted_indices = torch.max(outputs, dim=1)
            true_indices = torch.argmax(targets, dim=1)
            num_correct += (predicted_indices == true_indices).sum().item()
        average_loss = total_loss / len(train_dataloader)
        average_acc = num_correct / len(train_dataloader.dataset)
        train_history['train'].append(average_loss)
        train_history['acc'].append(average_acc)
        print(f'Epoch [{epoch + 1}/{num_epochs}], TrainLoss: {average_loss:.4f}, TrainAccuracy: {average_acc:.2f}%')
    return train_history

def main():
    label_path = 'pokemon-tcg-data-master 1999-2023.csv'
    images_path = 'images'
    
    df_label = load_labels(label_path)
    df_label_filtered = filter_labels(df_label, images_path)
    df_clean, label_onehot, n_classes = preprocess_labels(df_label_filtered)

    img_transform = create_transforms()
    dataset = MultiLabelDataset(df_data=df_clean, labels=label_onehot, transform=img_transform)
    train_dataset, val_dataset, test_dataset = split_dataset(dataset)
    train_dataloader, val_dataloader, test_dataloader = create_dataloaders(train_dataset, val_dataset, test_dataset)

    num_epochs = 30
    device = torch.device("cuda:0")
    model = initialize_model(n_classes, device)
    optimizer = torch.optim.Adam(model.parameters(), lr=0.01)
    loss_fn = nn.CrossEntropyLoss()

    train_history = train_model(model, train_dataloader, num_epochs, device, optimizer, loss_fn)

if __name__ == "__main__":
    main()