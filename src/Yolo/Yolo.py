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
from yolov5.utils.datasets import LoadImages
from yolov5.utils.general import non_max_suppression, scale_coords


class CardClassifier:
    def __init__(self, model_path, label_encoder_path, output_size=(640, 640)):
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.label_encoder = joblib.load(label_encoder_path)
        self.model = self.load_model(model_path)

        self.transform = transforms.Compose([
            transforms.Resize(output_size),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])

    def load_model(self, path):
        model = attempt_load(path, map_location=self.device)
        model.to(self.device)
        model.eval()
        return model

    def crop_set_symbol(self, image):
        standard_size = (600, 825)
        try:
            normalized_image = cv2.resize(image, standard_size)
        except cv2.error as e:
            print(f"Error resizing image: {e}")
            return

        symbol_region = normalized_image[775:825, 530:600]
        return symbol_region

    def predict(self, image):
        if image is None:
            print("No image provided or image could not be processed.")
            return None

        image = self.crop_set_symbol(image)
        if image is None:
            print("Error in cropping symbol region.")
            return None

        image = Image.fromarray(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
        image_tensor = self.transform(image)
        image_tensor = image_tensor.unsqueeze(0)

        plt.figure(figsize=(10, 10))
        plt.imshow(image)
        plt.title('Symbol')
        plt.show()

        with torch.no_grad():
            outputs = self.model(image_tensor.to(self.device))
            _, predicted = torch.max(outputs, 1)
            predicted_set = self.label_encoder.inverse_transform([predicted.item()])
        return predicted_set[0]

if __name__ == '__main__':
    classifier = CardClassifier(
        model_path='YOLOv5/pokemon_card_classifier.pt',
        label_encoder_path='YOLOv5/label_encoder.pkl'
    )
    image_path = 'PokemonCards/testImage/col1-33.png'
    image = cv2.imread(image_path)

    preprocessor = ImagePreprocessor()

    extracted = preprocessor.extract_card(image)
    predicted_set = classifier.predict(extracted)
    print("Predicted Set:", predicted_set)