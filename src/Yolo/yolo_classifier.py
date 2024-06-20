import os
import cv2
import torch
import pandas as pd
import numpy as np
from PIL import Image
from sklearn.preprocessing import LabelEncoder
from torch.utils.data import Dataset, DataLoader, random_split
from torchvision import transforms
import matplotlib.pyplot as plt

class YOLOv5CardClassifier:
    def __init__(self, data_csv, image_folder, cropped_folder, model_path='yolov5s.pt', device='cuda', output_size=(640, 640)):
        self.data_csv = data_csv
        self.cropped_folder = cropped_folder
        self.image_folder = image_folder
        self.output_size = output_size
        self.device = torch.device(device if torch.cuda.is_available() else 'cpu')
        self.model = self.load_model(model_path)

        transform = transforms.Compose([
            transforms.Resize(output_size),
            transforms.ToTensor(),
        ])

        self.dataset = PokemonDataset(csv_file=data_csv, img_dir=cropped_folder, transform=transform)
        train_size = int(0.8 * len(self.dataset))
        val_size = len(self.dataset) - train_size
        self.train_dataset, self.val_dataset = random_split(self.dataset, [train_size, val_size])

        self.train_loader = DataLoader(self.train_dataset, batch_size=8, shuffle=True)
        self.val_loader = DataLoader(self.val_dataset, batch_size=8, shuffle=False)

    def load_model(self, model_path):
        model = torch.hub.load('ultralytics/yolov5', 'custom', path=model_path).to(self.device)
        return model

    def train_model(self, epochs=50):
        self.model.train()
        for epoch in range(epochs):
            running_loss = 0.0
            for img_ids, inputs, labels in self.train_loader:
                inputs, labels = inputs.to(self.device), labels.to(self.device)
                results = self.model(inputs)
                loss = results[0]  # YOLOv5 returns a tuple with (loss, detection_output)
                self.model.zero_grad()
                loss.backward()
                self.model.optimizer.step()
                running_loss += loss.item()
            print(f'Epoch [{epoch + 1}/{epochs}], Loss: {running_loss / len(self.train_loader):.4f}')

    def evaluate_model(self):
        self.model.eval()
        total = correct = 0
        with torch.no_grad():
            for img_ids, inputs, labels in self.val_loader:
                inputs, labels = inputs.to(self.device), labels.to(self.device)
                results = self.model(inputs)
                detections = results.xyxy[0]  # Extracting detections
                for i, (img_id, detection, label) in enumerate(zip(img_ids, detections, labels)):
                    predicted_set = self.get_predicted_set(detection)
                    actual_set = self.dataset.encoder.inverse_transform([label.item()])[0]
                    if predicted_set == actual_set:
                        correct += 1
                    total += 1
                    print(f"Image ID: {img_id}, Predicted: {predicted_set}, Actual: {actual_set}")

        accuracy = 100 * correct / total
        print(f'Accuracy on validation set: {accuracy:.2f}%')

    def get_predicted_set(self, detection):
        if len(detection) > 0:
            conf, cls = detection[:, 4].max(0)
            set_name = self.model.names[int(cls.item())]
            return set_name
        return None

    def save_model(self, path='yolov5/pokemon_card_classifier.pt'):
        self.model.save(path)

    def save_label_encoder(self, path='yolov5/label_encoder.pkl'):
        import joblib
        joblib.dump(self.dataset.encoder, path)

if __name__ == '__main__':
    classifier = YOLOv5CardClassifier(
        data_csv='PokemonCards/cardAttributes/cardAttributes.csv',
        image_folder='PokemonCards/res50_images',
        cropped_folder='PokemonCards/cropped_images',
        model_path='path_to_your_yolov5_model.pt'
    )
    classifier.train_model(epochs=50)
    classifier.evaluate_model()
    classifier.save_model()
    classifier.save_label_encoder()