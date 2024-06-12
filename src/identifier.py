import json
import cv2
from fuzzywuzzy import process
from image_processor import ImagePreprocessor
from text_extractor import TextExtractor
import matplotlib.pyplot as plt

class CardIdentifier:
     
    def __init__(self, dataset_path, match_threshold=90):
        self.dataset_path = dataset_path
        self.match_threshold = match_threshold
        self.dataset = self.load_data()  # Load data during initialization

    def load_data(self):
        with open(self.dataset_path, 'r') as file:
            return json.load(file)

    def match_text(self, extracted_text, actual_text):
        if extracted_text and actual_text:
            match = process.extractOne(extracted_text, [actual_text], score_cutoff=self.match_threshold)
            return match is not None
        return False

    def identify_card(self, image_path):
        # Step 1: Preprocess the image to isolate the card regions
        preprocessor = ImagePreprocessor()
        processed_image, name_region, hp_region, moves_region = preprocessor.isolate_regions(image_path)
        
        # Display the processed image with defined regions
        plt.figure(figsize=(10, 10))
        plt.imshow(cv2.cvtColor(processed_image, cv2.COLOR_BGR2RGB))  # Convert BGR to RGB for displaying
        plt.title('Processed Image with Defined Regions')
        plt.show()


        if processed_image is None or name_region is None or hp_region is None or moves_region is None:
            print("Could not preprocess image or regions are not correctly identified.")
            return None

        # Step 2: Extract text from the isolated regions
        ocr_name = TextExtractor.extract_text_from_name(name_region)
        ocr_hp = TextExtractor.extract_text_from_hp(hp_region)
        ocr_moves = TextExtractor.extract_text_from_moves(moves_region)

        print("Extracted Name Text:", TextExtractor.post_process_text(ocr_name))
        print("Extracted HP Text:", TextExtractor.post_process_hp_text(ocr_hp))
        print("Extracted MoveText:", ocr_moves)

        # Step 3: Post-process the extracted text
        ocr_name = TextExtractor.post_process_text(ocr_name)
        ocr_hp = TextExtractor.post_process_hp_text(ocr_hp)
        
        # print("Extracted Name Text:", ocr_name)
        # print("Extracted HP Text:", ocr_hp)
        # print("Extracted MoveText:", ocr_moves)

        # Step 4: Match the text against the dataset
        for card in self.dataset:
            name_match = self.match_text(ocr_name, card['name'])
            hp_match = self.match_text(ocr_hp, card['hp'])
            moves_match = self.match_text(ocr_moves, card['caption'])

            if name_match and hp_match and moves_match:
                print(f"Identified Card: {card['name']}")
                print(f"Identified Card: {card['id']}")
                return card

        print("No matching card found.")
        return None

# Usage example (outside of this class definition)
# Ensure you have the path to the dataset and image correctly set
identifier = CardIdentifier('PokemonCards/downloaded_images/dataset.json')
identifier.identify_card('PokemonCards/testImage/base3-19.png')