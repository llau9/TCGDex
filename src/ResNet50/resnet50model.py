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

class PokemonCardClassifier:
    def __init__(self, data_csv, image_folder, cropped_folder, output_size=(224, 224)):
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

    def configure_model(self, num_classes):
        weights = ResNet50_Weights.DEFAULT
        self.model = resnet50(weights=weights)
        num_ftrs = self.model.fc.in_features
        self.model.fc = nn.Linear(num_ftrs, num_classes)
        self.model.to(self.device)

    def train_model(self, num_epochs=10):
        criterion = nn.CrossEntropyLoss()
        optimizer = optim.Adam(self.model.parameters(), lr=0.001)
        for epoch in range(num_epochs):
            self.model.train()
            running_loss = 0.0
            for img_ids, inputs, labels in self.train_loader:  # Add img_ids here
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
            for img_ids, inputs, labels in self.val_loader:  # Unpack img_ids here
                inputs, labels = inputs.to(self.device), labels.to(self.device)
                outputs = self.model(inputs)
                _, predicted = torch.max(outputs.data, 1)
                total += labels.size(0)
                correct += (predicted == labels).sum().item()

                predicted_sets = self.dataset.encoder.inverse_transform(predicted.cpu().numpy())
                actual_sets = self.dataset.encoder.inverse_transform(labels.cpu().numpy())

                # Print each prediction with its actual label and image ID
                for img_id, pred, actual in zip(img_ids, predicted_sets, actual_sets):
                    print(f"Image ID: {img_id}, Predicted: {pred}, Actual: {actual}")

        accuracy = 100 * correct / total
        print(f'Accuracy on validation set: {accuracy:.2f}%')

    def save_model(self, path='ResNet50/pokemon_card_classifier.pth'):
        """ Saves the model's state dictionary to a file. """
        torch.save(self.model.state_dict(), path)

    def save_label_encoder(self, path='ResNet50/label_encoder.pkl'):
        """ Saves the label encoder using joblib. """
        import joblib
        joblib.dump(self.dataset.encoder, path)

if __name__ == '__main__':
    classifier = PokemonCardClassifier(
        data_csv='PokemonCards/cardAttributes/cardAttributes.csv',
        image_folder='PokemonCards/res50_images',
        cropped_folder='PokemonCards/cropped_images'
    )
    # classifier.crop_images()
    # To crop images, comment out lines 73-79
    classifier.configure_model(num_classes=len(set(classifier.dataset.id_to_set.values())))
    classifier.train_model(10)
    classifier.evaluate_model()
    classifier.save_model()  # Save the trained model
    classifier.save_label_encoder()  # Save the label encoder
