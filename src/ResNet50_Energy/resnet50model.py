import cv2
import os
import pandas as pd
from PIL import Image
import torch
from torchvision import datasets, models, transforms
from torch.utils.data import DataLoader, random_split
from textDetect.image_processor import ImagePreprocessor
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
from sklearn.preprocessing import MultiLabelBinarizer


class PokemonDataset(Dataset):
    def __init__(self, csv_file, img_dir, transform=None):
        self.card_attrs = pd.read_csv(csv_file)
        self.img_dir = img_dir
        self.transform = transform

        self.id_to_type = {}
        self.types = []

        for index, row in self.card_attrs.iterrows():
            img_path = os.path.join(img_dir, f"{row['id']}.png")
            if os.path.exists(img_path):
                # Parse types which are expected to be stored as list
                card_types = eval(row['types'])
                self.id_to_type[row['id']] = card_types
                self.types.extend(card_types)

        self.types = list(set(self.types))  # Remove duplicates
        self.encoder = MultiLabelBinarizer()
        self.encoder.fit([self.types])

    def __len__(self):
        return len(self.id_to_type)

    def __getitem__(self, idx):
        img_id = list(self.id_to_type.keys())[idx]
        img_name = os.path.join(self.img_dir, f"{img_id}.png")
        image = Image.open(img_name).convert('RGB')
        types = self.id_to_type[img_id]

        label = self.encoder.transform([types])[0]

        if self.transform:
            image = self.transform(image)

        return img_id, image, torch.tensor(label, dtype=torch.float)  # Use float for BCE loss

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
                    self.crop_energy_symbol(image, output_path)

    def crop_energy_symbol(self, image, output_path):
        # Resize image to a standard size for consistency
        standard_size = (600, 825)  # Example size, adjust as needed
        try:
            normalized_image = cv2.resize(image, standard_size)
        except cv2.error as e:
            print(f"Error resizing image: {e}")
            return

        # Define the coordinates for the set symbol region (adjust these as needed)
        symbol_region = normalized_image[0:90, 450:600]

        # Save the cropped region to the specified output path
        cv2.imwrite(output_path, symbol_region)

    def configure_model(self):
        # Calculate number of classes based on the unique labels in the MultiLabelBinarizer
        num_classes = len(self.dataset.encoder.classes_)
        weights = ResNet50_Weights.DEFAULT
        self.model = resnet50(weights=weights)
        num_ftrs = self.model.fc.in_features
        # Adjust the output layer for multi-label classification based on the actual number of classes
        self.model.fc = nn.Linear(num_ftrs, num_classes)
        self.model.to(self.device)

    def train_model(self, num_epochs=10):
        criterion = nn.BCEWithLogitsLoss()  # Adjusted for multi-label
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
        total = 0
        exact_match_count = 0
        hamming_loss_sum = 0

        with torch.no_grad():
            for img_ids, inputs, labels in self.val_loader:
                inputs, labels = inputs.to(self.device), labels.to(self.device)
                outputs = self.model(inputs)

                # Sigmoid function to convert outputs to probabilities
                probs = torch.sigmoid(outputs)
                # Applying threshold to convert probabilities to binary outputs
                predicted = (probs > 0.5).float()

                # Update total count
                total += labels.size(0)
                # Check exact matches (all labels correctly predicted)
                exact_match_count += (predicted == labels).all(dim=1).sum().item()
                # Calculate Hamming loss (fraction of wrong labels per sample)
                hamming_loss_sum += (predicted != labels).sum().item() / labels.numel()

                # Decode the predicted and actual labels
                predicted_types = self.dataset.encoder.inverse_transform(predicted.cpu().numpy())
                actual_types = self.dataset.encoder.inverse_transform(labels.cpu().numpy())

                # Print the comparison of predicted vs actual for each image
                for img_id, pred, act in zip(img_ids, predicted_types, actual_types):
                    print(f"Image ID: {img_id}, Predicted: {pred}, Actual: {act}")

        # Calculate exact match ratio and average Hamming loss
        exact_match_ratio = 100 * exact_match_count / total
        average_hamming_loss = hamming_loss_sum / total

        print(f'Exact Match Ratio on validation set: {exact_match_ratio:.2f}%')
        print(f'Average Hamming Loss on validation set: {average_hamming_loss:.4f}')


    def save_model(self, path='ResNet50_Energy/pokemon_card_classifier.pth'):
        """ Saves the model's state dictionary to a file. """
        torch.save(self.model.state_dict(), path)

    def save_label_encoder(self, path='ResNet50_Energy/label_encoder.pkl'):
        """ Saves the label encoder using joblib. """
        import joblib
        joblib.dump(self.dataset.encoder, path)

if __name__ == '__main__':
    classifier = PokemonCardClassifier(
        data_csv='PokemonCards/cardAttributes/cardAttributes.csv',
        image_folder='PokemonCards/res50_images',
        cropped_folder='PokemonCards/cropped_images_energy'
    )
    # classifier.crop_images()
    # To load images, comment out lines 76-82

    classifier.configure_model()
    classifier.train_model(10)
    classifier.evaluate_model()
    classifier.save_model()  # Save the trained model
    classifier.save_label_encoder()  # Save the label encoder
