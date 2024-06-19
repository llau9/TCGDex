import torch
from torchvision import transforms
from PIL import Image
import joblib
import cv2
import os
import pandas as pd
from PIL import Image
import torch
from torchvision import datasets, models, transforms
from torch.utils.data import DataLoader, random_split
from image_processor import ImagePreprocessor
from torch.utils.data import Dataset, DataLoader
import torch.nn as nn
import torch.optim as optim
import numpy as np
from torchvision.models import resnet50, ResNet50_Weights
import torch
from torch.utils.data import Dataset, DataLoader
from torchvision import transforms
from sklearn.preprocessing import LabelEncoder
import pandas as pd
import os
from PIL import Image
import matplotlib.pyplot as plt
from PIL import Image as PILImage  # Import PIL Image to avoid confusion with torchvision.transforms

class CardClassifier:
    def __init__(self, model_path, label_encoder_path, output_size=(224, 224)):
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        
        # Load the label encoder
        self.label_encoder = joblib.load(label_encoder_path)
        
        # Load the model with the correct number of classes
        self.model = self.load_model(model_path, output_size)

        # Transformations to be applied on input images
        self.transform = transforms.Compose([
            transforms.Resize(output_size),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
        ])

    def crop_set_symbol(self, image):
        # Assuming the image is read using cv2 and is in BGR format
        standard_size = (600, 825)
        try:
            normalized_image = cv2.resize(image, standard_size)
        except cv2.error as e:
            print(f"Error resizing image: {e}")
            return None

        symbol_region = normalized_image[0:90, 450:600]
        return symbol_region

    def load_model(self, path, output_size):
        num_classes = len(self.label_encoder.classes_)
        model = resnet50(pretrained=False)
        num_ftrs = model.fc.in_features
        model.fc = nn.Linear(num_ftrs, num_classes)
        model.load_state_dict(torch.load(path, map_location=self.device))
        model.to(self.device)
        model.eval()
        return model

    def predict(self, image):
        if image is None:
            print("No image provided or image could not be processed.")
            return None

        image = self.crop_set_symbol(image)
        if image is None:
            print("Error in cropping symbol region.")
            return None

        # Convert OpenCV image (numpy array) to PIL image
        image = Image.fromarray(image[:, :, ::-1])  # Convert BGR to RGB

        # Apply the transformations
        image_tensor = self.transform(image)
        image_tensor = image_tensor.unsqueeze(0)  # Add batch dimension

        with torch.no_grad():
            outputs = self.model(image_tensor.to(self.device))
            _, predicted = torch.max(outputs, 1)
            predicted_set = self.label_encoder.inverse_transform([predicted.item()])
        return predicted_set[0]

if __name__ == '__main__':
    classifier = CardClassifier(
        model_path='ResNet50_Energy/pokemon_card_classifier.pth',
        label_encoder_path='ResNet50_Energy/label_encoder.pkl'
    )
    image_path = 'PokemonCards/testImage/bw2-2.png'
    image = cv2.imread(image_path)
    if image is not None:
        predicted_set = classifier.predict(image)
        print("Predicted Set:", predicted_set)
    else:
        print("Failed to load image.")