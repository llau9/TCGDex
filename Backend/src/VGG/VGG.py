import os
import numpy as np
import pandas as pd
from PIL import Image
import matplotlib.pyplot as plt
from sklearn.preprocessing import LabelEncoder, OneHotEncoder
from sklearn.model_selection import train_test_split
from tensorflow.keras.applications.vgg16 import VGG16, preprocess_input
from tensorflow.keras.preprocessing.image import load_img, img_to_array
from tensorflow.keras.layers import Dense, Flatten, Dropout, BatchNormalization
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import RMSprop
from tensorflow.keras.callbacks import ReduceLROnPlateau, EarlyStopping, ModelCheckpoint

class VGG16CardClassifier:
    def __init__(self, data_csv, image_folder, output_size=(224, 224)):
        self.data_csv = data_csv
        self.image_folder = image_folder
        self.output_size = output_size
        self.label_encoder = LabelEncoder()
        self.onehot_encoder = OneHotEncoder(sparse=False)
        
        # Initialize model
        self.model = self.build_model()

    def preprocess_card_label(self, card_label):
        parts = card_label.split('_')
        set_name = parts[0]
        card_number = parts[1]
        expansion = parts[2]
        return set_name, card_number, expansion

    def load_dataset(self):
        # Initialize lists to store image paths and corresponding labels
        image_paths = []
        set_names = []
        card_numbers = []
        expansions = []

        # Iterate through each file in the folder
        for filename in os.listdir(self.image_folder):
            file_path = os.path.join(self.image_folder, filename)
            if os.path.isdir(file_path):
                continue
            try:
                card_label = os.path.splitext(filename)[0]
                set_name, card_number, expansion = self.preprocess_card_label(card_label)
                if card_number.isdigit():
                    image_paths.append(file_path)
                    set_names.append(set_name)
                    card_numbers.append(card_number)
                    expansions.append(expansion)
            except Exception as e:
                print(f"Error processing file {filename}: {e}")

        # Create a DataFrame from the lists
        df = pd.DataFrame({
            'image_path': image_paths,
            'set_name': set_names,
            'card_number': card_numbers,
            'expansion': expansions
        })

        return df

    def encode_labels(self, df):
        integer_encoded = self.label_encoder.fit_transform(df['expansion'])
        integer_encoded = integer_encoded.reshape(len(integer_encoded), 1)
        onehot_encoded = self.onehot_encoder.fit_transform(integer_encoded)
        return onehot_encoded

    def load_and_preprocess_image(self, image_path):
        image = load_img(image_path, target_size=self.output_size)
        image = img_to_array(image)
        image = preprocess_input(image)
        return image

    def build_model(self):
        base_model = VGG16(weights='imagenet', include_top=False, input_shape=(224, 224, 3))
        x = base_model.output
        x = Flatten()(x)
        x = Dense(1024, activation='relu', kernel_regularizer=l2(0.001))(x)
        x = BatchNormalization()(x)
        x = Dropout(0.5)(x)
        x = Dense(512, activation='relu', kernel_regularizer=l2(0.001))(x)
        x = BatchNormalization()(x)
        x = Dropout(0.5)(x)
        expansion_pred = Dense(len(self.label_encoder.classes_), activation='softmax', name='expansion')(x)
        
        model = Model(inputs=base_model.input, outputs=expansion_pred)
        optimizer = RMSprop(learning_rate=0.0001)
        model.compile(optimizer=optimizer, loss='categorical_crossentropy', metrics=['accuracy'])
        return model

    def train_model(self, epochs=10):
        df = self.load_dataset()
        onehot_encoded = self.encode_labels(df)
        images = np.array([self.load_and_preprocess_image(path) for path in df['image_path']])

        train_images, test_images, train_labels, test_labels = train_test_split(
            images, onehot_encoded, test_size=0.2, random_state=42)

        # Callbacks
        reduce_lr = ReduceLROnPlateau(monitor='val_loss', factor=0.1, patience=3, min_lr=1e-6, verbose=1)
        early_stopping = EarlyStopping(monitor='val_loss', patience=5, restore_best_weights=True, verbose=1)
        checkpoint = ModelCheckpoint('vgg16_model_weights.h5', monitor='val_loss', save_best_only=True, mode='min', verbose=1)

        history = self.model.fit(
            train_images, train_labels,
            epochs=epochs,
            validation_data=(test_images, test_labels),
            callbacks=[reduce_lr, early_stopping, checkpoint]
        )

        test_loss, test_accuracy = self.model.evaluate(test_images, test_labels, verbose=2)
        print("Test Loss:", test_loss)
        print("Test Accuracy:", test_accuracy)

    def save_model(self, path='vgg16_card_classifier.h5'):
        self.model.save(path)

    def load_model(self, path):
        self.model = load_model(path)

# Example usage
if __name__ == '__main__':
    classifier = VGG16CardClassifier(
        data_csv='path_to_your_csv_file.csv',
        image_folder='path_to_your_image_folder'
    )
    classifier.train_model(epochs=10)
    classifier.save_model()