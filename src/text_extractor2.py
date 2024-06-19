import numpy as np
import cv2
from data_processor import ImageDownloader
from PIL import Image
import pandas as pd
import easyocr
import matplotlib.pyplot as plt

class TextExtractor:
    
    # Create a reader instance for EasyOCR
    reader = easyocr.Reader(['en'], gpu=True)  # Set gpu=False if you don't have CUDA installed

    @staticmethod
    def extract_text_with_easyocr_name(image):
        # Ensure the image is in the right color format for EasyOCR
        if len(image.shape) == 3 and image.shape[2] == 3:
            image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        
        # Use EasyOCR to detect text with an allowlist of lowercase alphabets
        results = TextExtractor.reader.readtext(image, allowlist='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')

        # Filter results to include only those above the probability threshold
        high_prob_results = [result for result in results if result[2] >= 0.80]

        # Check if any high probability results were found
        if high_prob_results:
            # Concatenate all high probability text results
            text = " ".join([result[1] for result in high_prob_results])
        else:
            # If no high probability results, sort all results by probability
            if results:
                results.sort(key=lambda x: x[2], reverse=True)
                text = results[0][1]  # Take the highest probability result
            else:
                text = ""

        return text.strip()

 
    @staticmethod
    def extract_text_with_easyocr_moves(image):
        # Ensure the image is in the right color format for EasyOCR
        if len(image.shape) == 3 and image.shape[2] == 3:
            image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        # Use EasyOCR to detect text
        results = TextExtractor.reader.readtext(image)
        # Concatenate the text from each detection
        text = " ".join([result[1] for result in results])
        return text.strip()
    

    @staticmethod
    def extract_text_with_easyocr_numbers(image):
        # Ensure the image is in the right color format for EasyOCR
        if len(image.shape) == 3 and image.shape[2] == 3:
            image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        # Use EasyOCR to detect text
        results = TextExtractor.reader.readtext(image, allowlist= '0123456789')
        results.sort(key=lambda x: x[2], reverse=True)
        # Select the result with the highest probability
        if results:
            highest_prob_result = results[0]
            text = highest_prob_result[1]
        else:
            text = ""
        return text.strip()
    

    @staticmethod
    def extract_text_from_name(region):
        # Preprocess the region if necessary, e.g., resizing, thresholding
        gray = cv2.cvtColor(region, cv2.COLOR_BGR2GRAY) if len(region.shape) == 3 else region
        scale_factor = 5 # Reduced from 2 to 1.5
        scaled_thresh = cv2.resize(gray, None, fx=scale_factor, fy=scale_factor, interpolation=cv2.INTER_LINEAR)

        # Extract text using EasyOCR
        text = TextExtractor.extract_text_with_easyocr_name(scaled_thresh)
        return text

    @staticmethod
    def extract_text_from_hp(region):
        # Preprocess the region if necessary, e.g., resizing, thresholding
        gray = cv2.cvtColor(region, cv2.COLOR_BGR2GRAY) if len(region.shape) == 3 else region
        # _, thresh = cv2.threshold(gray, 200, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        scale_factor = 5 # Reduced from 2 to 1.5
        scaled_thresh = cv2.resize(gray, None, fx=scale_factor, fy=scale_factor, interpolation=cv2.INTER_LINEAR)
        # Extract text using EasyOCR
        text = TextExtractor.extract_text_with_easyocr_numbers(scaled_thresh)

        return text

    @staticmethod
    def extract_text_from_moves(region):
        # Preprocess the region if necessary, e.g., resizing, thresholding
        gray = cv2.cvtColor(region, cv2.COLOR_BGR2GRAY) if len(region.shape) == 3 else region
        scale_factor = 2 # Reduced from 2 to 1.5
        scaled_thresh = cv2.resize(gray, None, fx=scale_factor, fy=scale_factor, interpolation=cv2.INTER_LINEAR)
        # Extract text using EasyOCR
        text = TextExtractor.extract_text_with_easyocr_moves(scaled_thresh)

        return text

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
    
