import os
import cv2
import torch
import numpy as np
import pandas as pd
from PIL import Image
from torchvision import transforms
import matplotlib.pyplot as plt

class YOLOv5Model:
    def __init__(self, model_path='yolov5s.pt', device='cuda'):
        self.device = torch.device(device if torch.cuda.is_available() else 'cpu')
        self.model = torch.hub.load('ultralytics/yolov5', 'custom', path=model_path).to(self.device)

    def detect(self, image):
        results = self.model(image)
        return results

class CardDetector:
    def __init__(self, model, dataset_path, image_dir='images'):
        self.model = model
        self.dataset_path = dataset_path
        self.image_dir = image_dir
        self.df_labels = self.load_labels()

    def load_labels(self):
        return pd.read_csv(self.dataset_path)

    def preprocess_image(self, image_path):
        image = Image.open(image_path)
        transform = transforms.Compose([
            transforms.Resize((640, 640)),
            transforms.ToTensor(),
        ])
        return transform(image).unsqueeze(0).to(self.model.device)

    def detect_cards(self, image_path):
        image = self.preprocess_image(image_path)
        results = self.model.detect(image)
        return results

    def visualize_detections(self, image_path, results):
        img = cv2.imread(image_path)
        for result in results.xyxy[0].cpu().numpy():
            x1, y1, x2, y2, conf, cls = result
            label = f'{self.model.model.names[int(cls)]} {conf:.2f}'
            cv2.rectangle(img, (int(x1), int(y1)), (int(x2), int(y2)), (255, 0, 0), 2)
            cv2.putText(img, label, (int(x1), int(y1) - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.9, (255, 0, 0), 2)
        
        plt.figure(figsize=(10, 10))
        plt.imshow(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
        plt.title('Detected Pokémon Cards')
        plt.show()
