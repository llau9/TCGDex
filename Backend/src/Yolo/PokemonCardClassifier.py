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

class PokemonCardClassifier:
    def __init__(self, data_csv, image_folder, cropped_folder, output_size=(640, 640)):
        self.data_csv = data_csv
        self.cropped_folder = cropped_folder
        self.image_folder = image_folder
        self.output_size = output_size
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model = None

        transform = transforms.Compose([
            transforms.Resize(output_size),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])

        self.dataset = PokemonDataset(csv_file=data_csv, img_dir=cropped_folder, transform=transform)
        train_size = int(0.8 * len(self.dataset))
        val_size = len(self.dataset) - train_size
        self.train_dataset, self.val_dataset = random_split(self.dataset, [train_size, val_size])

        self.train_loader = DataLoader(self.train_dataset, batch_size=32, shuffle=True)
        self.val_loader = DataLoader(self.val_dataset, batch_size=32, shuffle=False)

    def configure_model(self, weights_path):
        self.model = attempt_load(weights_path, map_location=self.device)
        self.model.to(self.device)
        self.model.eval()

    def crop_images(self):
        attributes = pd.read_csv(self.data_csv)
        for index, row in attributes.iterrows():
            image_path = os.path.join(self.image_folder, f"{row['id']}.png")
            output_path = os.path.join(self.cropped_folder, f"{row['id']}.png")
            if os.path.exists(image_path):
                image = cv2.imread(image_path)
                if image is not None:
                    self.crop_set_symbol(image, output_path)

    def crop_set_symbol(self, image, output_path):
        # Resize image to a standard size for consistency
        standard_size = (600, 825)  # Example size, adjust as needed
        try:
            normalized_image = cv2.resize(image, standard_size)
        except cv2.error as e:
            print(f"Error resizing image: {e}")
            return

        # Define the coordinates for the set symbol region (adjust these as needed)
        symbol_region = normalized_image[775:825, 530:600]

        # Save the cropped region to the specified output path
        cv2.imwrite(output_path, symbol_region)

    def train_model(self, num_epochs=10):
        criterion = nn.CrossEntropyLoss()
        optimizer = optim.Adam(self.model.parameters(), lr=0.001)
        for epoch in range(num_epochs):
            self.model.train()
            running_loss = 0.0
            for img_ids, inputs, labels in self.train_loader:
                inputs, labels = inputs.to(self.device), labels.to(self.device)
                optimizer.zero_grad()
                outputs = self.model(inputs)
                loss = criterion(outputs, labels)
                loss.backward()
                optimizer.step()
                running_loss += loss.item()
            print(f'Epoch [{epoch + 1}/{num_epochs}], Loss: {running_loss / len(self.train_loader):.4f}')

    def evaluate_model(self):
        self.model.eval()
        total = correct = 0
        with torch.no_grad():
            for img_ids, inputs, labels in self.val_loader:
                inputs, labels = inputs.to(self.device), labels.to(self.device)
                outputs = self.model(inputs)
                _, predicted = torch.max(outputs.data, 1)
                total += labels.size(0)
                correct += (predicted == labels).sum().item()

                predicted_sets = self.dataset.encoder.inverse_transform(predicted.cpu().numpy())
                actual_sets = self.dataset.encoder.inverse_transform(labels.cpu().numpy())

                for img_id, pred, actual in zip(img_ids, predicted_sets, actual_sets):
                    print(f"Image ID: {img_id}, Predicted: {pred}, Actual: {actual}")

        accuracy = 100 * correct / total
        print(f'Accuracy on validation set: {accuracy:.2f}%')

    def save_model(self, path='YOLOv5/pokemon_card_classifier.pt'):
        torch.save(self.model.state_dict(), path)

    def save_label_encoder(self, path='YOLOv5/label_encoder.pkl'):
        joblib.dump(self.dataset.encoder, path)

if __name__ == '__main__':
    classifier = PokemonCardClassifier(
        data_csv='PokemonCards/cardAttributes/cardAttributes.csv',
        image_folder='PokemonCards/res50_images',
        cropped_folder='PokemonCards/cropped_images'
    )
    classifier.configure_model(weights_path='YOLOv5/yolov5s.pt')  # Path to YOLOv5 weights
    classifier.train_model(10)
    classifier.evaluate_model()
    classifier.save_model()
    classifier.save_label_encoder()