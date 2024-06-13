import os
import numpy as np
import PIL
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, OneHotEncoder
from tensorflow.keras.preprocessing.image import load_img, img_to_array
from keras.callbacks import ReduceLROnPlateau, EarlyStopping, ModelCheckpoint
from tensorflow.keras.applications.vgg16 import preprocess_input
from tensorflow.keras.applications import VGG16
from tensorflow.keras.layers import Dense, Flatten, Dropout, BatchNormalization
from tensorflow.keras.models import Model, load_model
from tensorflow.keras.optimizers import RMSprop
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.regularizers import l2
import pandas as pd
import matplotlib.pyplot as plt
from PIL import Image

# Function to preprocess card label from filename
def preprocess_card_label(card_label):
    parts = card_label.split('_')
    set_name = parts[0]
    card_number = parts[1]
    expansion = parts[2]
    return set_name, card_number, expansion

# Path to the folder containing all the images
folder_path = "tcg_dataset"

# Initialize lists to store image paths and corresponding labels
image_paths = []
set_names = []
card_numbers = []
expansions = []

# Iterate through each file in the folder
for filename in os.listdir(folder_path):
    file_path = os.path.join(folder_path, filename)
    # Skip directories
    if os.path.isdir(file_path):
        continue
    # Extract information from filename
    try:
        card_label = os.path.splitext(filename)[0]  # Remove file extension
        set_name, card_number, expansion = preprocess_card_label(card_label)
        # Check if card number is a number
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

# Encode labels
label_encoder = LabelEncoder()
integer_encoded = label_encoder.fit_transform(df['expansion'])
onehot_encoder = OneHotEncoder(sparse=False)
integer_encoded = integer_encoded.reshape(len(integer_encoded), 1)
onehot_encoded = onehot_encoder.fit_transform(integer_encoded)

# Load images and preprocess
def load_and_preprocess_image(image_path):
    image = load_img(image_path, target_size=(224, 224))
    image = img_to_array(image)
    image = preprocess_input(image)
    return image

images = np.array([load_and_preprocess_image(path) for path in df['image_path']])
expansions_onehot = onehot_encoded

# Split the dataset
train_images, test_images, train_expansions_onehot, test_expansions_onehot = train_test_split(
    images, expansions_onehot, test_size=0.2, random_state=42)

# Define the model
base_model = VGG16(weights='imagenet', include_top=False, input_shape=(224, 224, 3))
x = base_model.output
x = Flatten()(x)
x = Dense(1024, activation='relu', kernel_regularizer=l2(0.001))(x)
x = BatchNormalization()(x)
x = Dropout(0.5)(x)
x = Dense(512, activation='relu', kernel_regularizer=l2(0.001))(x)
x = BatchNormalization()(x)
x = Dropout(0.5)(x)
expansion_pred = Dense(len(np.unique(df['expansion'])), activation='softmax', name='expansion')(x)

model = Model(inputs=base_model.input, outputs=expansion_pred)

optimizer = RMSprop(learning_rate=0.0001)
model.compile(optimizer=optimizer, loss='categorical_crossentropy', metrics=['accuracy'])

# Callbacks
reduce_lr = ReduceLROnPlateau(monitor='val_loss', factor=0.1, patience=3, min_lr=1e-6, verbose=1)
early_stopping = EarlyStopping(monitor='val_loss', patience=5, restore_best_weights=True, verbose=1)
checkpoint = ModelCheckpoint('model_weights.h5', monitor='val_loss', save_best_only=True, mode='min', verbose=1)

# Train the model
history = model.fit(
    train_images,  # Squeeze out the extra dimension
    train_expansions_onehot,
    epochs=10,
    validation_data=(test_images, test_expansions_onehot),  # Squeeze out the extra dimension
    callbacks=[reduce_lr, early_stopping, checkpoint]
)

# Evaluate the model
test_loss, test_accuracy = model.evaluate(test_images, test_expansions_onehot, verbose=2)
print("Test Loss:", test_loss)
print("Test Accuracy:", test_accuracy)

# Save the model weights
model.save_weights('model_weights.h5')

# Load the model weights
model = load_model('model_weights.h5')
optimizer = RMSprop(learning_rate=0.0001)  # Use the same optimizer as before
model.compile(optimizer=optimizer, loss='categorical_crossentropy', metrics=['accuracy'])
