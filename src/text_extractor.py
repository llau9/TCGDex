import numpy as np
import cv2
from data_processor import ImageDownloader
from PIL import Image
import pytesseract
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report
import matplotlib.pyplot as plt

pytesseract.pytesseract.tesseract_cmd = r"C:\Program Files\Tesseract-OCR\tesseract.exe"

class TextExtractor:
    
    @staticmethod
    def extract_text_from_name(region):
        gray = cv2.cvtColor(region, cv2.COLOR_BGR2GRAY) if len(region.shape) == 3 else region
        _, thresh = cv2.threshold(gray, 200, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

        kernel = np.ones((1,1), np.uint8)
        gray = cv2.dilate(thresh, kernel, iterations = 1)
        kernel = np.ones((1,1), np.uint8)
        gray = cv2.erode(gray, kernel, iterations = 1)
        gray = cv2.morphologyEx(gray, cv2.MORPH_CLOSE, kernel)
        gray = cv2.medianBlur(gray, 3)

        gray = cv2.bitwise_not(gray)
        kernel = np.ones((2,2), np.uint8)
        gray = cv2.erode(gray, kernel, iterations = 1)
        gray = cv2.bitwise_not(gray)

        scale_factor = 5 # Reduced from 2 to 1.5
        scaled_thresh = cv2.resize(thresh, None, fx=scale_factor, fy=scale_factor, interpolation=cv2.INTER_LINEAR)
        plt.figure(figsize=(10, 10))
        plt.imshow(scaled_thresh, cmap='gray')  # Display the image in grayscale
        plt.title('Processed Image with Defined Regions')
        plt.show()
        text = pytesseract.image_to_string(scaled_thresh, lang='eng', config='--psm 7 --oem 1')
        return text.strip()
    
    @staticmethod
    def extract_text_from_hp(region):
        # Convert to grayscale
        gray = cv2.cvtColor(region, cv2.COLOR_BGR2GRAY) if len(region.shape) == 3 else region
        _, thresh = cv2.threshold(gray, 200, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

        kernel = np.ones((1,1), np.uint8)
        gray = cv2.dilate(thresh, kernel, iterations = 1)
        kernel = np.ones((1,1), np.uint8)
        gray = cv2.erode(gray, kernel, iterations = 1)
        gray = cv2.morphologyEx(gray, cv2.MORPH_CLOSE, kernel)
        gray = cv2.medianBlur(gray, 3)

        gray = cv2.bitwise_not(gray)
        kernel = np.ones((2,2), np.uint8)
        gray = cv2.erode(gray, kernel, iterations = 1)
        gray = cv2.bitwise_not(gray)

        # Use PSM 7 for single line text and OEM 3 for LSTM engine
        config = '--psm 7 --oem 3'
        scale_factor = 5 # Reduced from 2 to 1.5
        scaled_thresh = cv2.resize(thresh, None, fx=scale_factor, fy=scale_factor, interpolation=cv2.INTER_LINEAR)
        # Extract text using Tesseract
        text = pytesseract.image_to_string(scaled_thresh, lang='eng', config=config)
        plt.figure(figsize=(10, 10))
        plt.imshow(scaled_thresh, cmap='gray')  # Display the image in grayscale
        plt.title('Processed Image with Defined Regions')
        plt.show()
        return text.strip()

    @staticmethod
    def extract_text_from_moves(region):
        gray = cv2.cvtColor(region, cv2.COLOR_BGR2GRAY) if len(region.shape) == 3 else region
        _, thresh = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        kernel = np.ones((1,1), np.uint8)
        gray = cv2.dilate(thresh, kernel, iterations = 1)
        kernel = np.ones((1,1), np.uint8)
        gray = cv2.erode(gray, kernel, iterations = 1)
        gray = cv2.morphologyEx(gray, cv2.MORPH_CLOSE, kernel)
        gray = cv2.medianBlur(gray, 3)

        gray = cv2.bitwise_not(gray)
        kernel = np.ones((2,2), np.uint8)
        gray = cv2.erode(gray, kernel, iterations = 1)
        gray = cv2.bitwise_not(gray)

        text = pytesseract.image_to_string(thresh, lang='eng', config='--psm 11 --oem 1')
        plt.figure(figsize=(10, 10))
        plt.imshow(thresh, cmap='gray')  # Display the image in grayscale
        plt.title('Processed Image with Defined Regions')
        plt.show()
        return text.strip()

    @staticmethod
    def prepare_features(dataset):
        features = []
        for data in dataset:
            image = cv2.imread(data['image_path'])
            region = image  # Assuming whole image, or specify the region
            extracted_text = TextExtractor.extract_text_from_region(region)
            features.append({'text': extracted_text, 'label': data['set_name']})
        return pd.DataFrame(features)
    
    @staticmethod
    def post_process_hp_text(hp_text):
        """
        Post-process OCR-extracted HP text to adjust for common OCR mistakes.
        """

        # Replace common OCR misreadings specific to HP values
        hp_text = hp_text.replace('O', '0').replace('o', '0').replace('B', '8').replace('l', '1').replace('I', '1')

        # Remove any non-numeric characters, assuming HP is numeric
        hp_text = ''.join(filter(str.isdigit, hp_text))

        if len(hp_text) > 3:
            if hp_text[0] != '1':
                # If it's longer than three digits and the first digit is not 1,
                # truncate to the first two digits
                hp_text = hp_text[:2]
            else:
                # If the first digit is 1, allow up to three digits
                hp_text = hp_text[:3]
        elif len(hp_text) == 3 and hp_text[0] != '1':
            # If it's exactly three digits but the first is not 1, also truncate to two digits
            hp_text = hp_text[:2]

        return hp_text
    

    @staticmethod
    def post_process_text(text):
        """
        Post-process OCR-extracted text for names and moves to adjust for common OCR mistakes.
        This replaces numeric characters with alphabetic ones where common mistakes are made.
        """

        # Replace common OCR misreadings that might be expected in names/moves
        corrections = {
            '0': 'O',  # Zero to letter O
            '1': 'I',  # Number 1 to letter I
            '5': 'S',  # Number 5 to letter S if it makes sense in the context
            '8': 'B',  # Number 8 to letter B if it makes sense in the context
            # ... Add any other specific replacements needed based on observed OCR errors
        }
        
        # Apply corrections
        for wrong, correct in corrections.items():
            text = text.replace(wrong, correct)

        text = ''.join(char for char in text if char.isalnum() or char.isspace())

        return text