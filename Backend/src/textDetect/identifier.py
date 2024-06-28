import json
import pandas as pd
import cv2
from skimage.transform import (hough_line, hough_line_peaks)
from fuzzywuzzy import fuzz, process
from textDetect.image_processor import ImagePreprocessor
from textDetect.text_extractor2 import TextExtractor
import matplotlib.pyplot as plt
import ast

class CardIdentifier:
     
    def __init__(self, dataset_path, match_threshold=90):
        self.dataset_path = dataset_path
        self.match_threshold = match_threshold
        self.dataset = self.load_data()  # Load data during initialization

    def load_data(self):
        # Load the CSV directly into a pandas DataFrame
        data = pd.read_csv(self.dataset_path)
        # Convert string representations of lists, dictionaries safely to Python objects
        list_dict_fields = ['types', 'subtypes', 'evolvesTo', 'abilities', 'attacks', 'weaknesses', 'retreatCost', 'nationalPokedexNumbers', 'resistances', 'rules']
        for field in list_dict_fields:
            data[field] = data[field].apply(lambda x: ast.literal_eval(x) if pd.notna(x) else None)
        return data

    def match_text(self, extracted_text, actual_text):
        if extracted_text and actual_text:
            # Using partial ratio for a less strict comparison
            match = process.extractOne(extracted_text, [actual_text], scorer=fuzz.partial_ratio, score_cutoff=self.match_threshold)
            return match is not None
        return False

    
    def compare_attacks_abilities(self, ocr_text, card_data):

        # Initialize empty list to collect possible matches
        possible_matches = []

        # Check attacks
        for attack in card_data['attacks'] if card_data['attacks'] is not None else []:
            # Ensure that 'name' and 'text' are not None and are strings before matching
            if 'name' in attack and isinstance(attack['name'], str) and self.match_text(ocr_text, attack['name']):
                possible_matches.append(attack)
            if 'text' in attack and isinstance(attack['text'], str) and self.match_text(ocr_text, attack['text']):
                possible_matches.append(attack)

        # Check abilities
        for ability in card_data['abilities'] if card_data['abilities'] is not None else []:
            # Ensure that 'name' and 'text' are not None and are strings before matching
            if 'name' in ability and isinstance(ability['name'], str) and self.match_text(ocr_text, ability['name']):
                possible_matches.append(ability)
            if 'text' in ability and isinstance(ability['text'], str) and self.match_text(ocr_text, ability['text']):
                possible_matches.append(ability)

        return possible_matches


    def identify_card(self, image_path):
        preprocessor = ImagePreprocessor()
        processed_image, name_region, hp_region, moves_region = preprocessor.isolate_regions(image_path)

        # Display processed regions
        plt.figure(figsize=(10, 10))
        plt.imshow(cv2.cvtColor(processed_image, cv2.COLOR_BGR2RGB))
        plt.title('Processed Image with Defined Regions')
        plt.show()


        # Extract text
        ocr_name = TextExtractor.extract_text_from_name(name_region)
        ocr_hp = TextExtractor.extract_text_from_hp(hp_region)
        ocr_moves = TextExtractor.extract_text_from_moves(moves_region)

        # Post-process text for better matching
        ocr_name = TextExtractor.post_process_text(ocr_name)
        ocr_hp = TextExtractor.post_process_hp_text(ocr_hp)

        print("Extracted Name Text:", TextExtractor.post_process_text(ocr_name))
        print("Extracted HP Text:", TextExtractor.post_process_hp_text(ocr_hp))
        print("Extracted MoveText:", TextExtractor.post_process_text(ocr_moves))


        # Attempt to match text with dataset entries
        for index, card in self.dataset.iterrows():
            name_match = self.match_text(ocr_name, card['name'])
            hp_match = self.match_text(ocr_hp, str(card['hp']))
            matches = self.compare_attacks_abilities(ocr_moves, card)
            if name_match and hp_match and matches:
                print(f"Identified Card: {card['name']} (ID: {card['id']})")
                return card

        print("No matching card found.")
        return None

# Example usage
identifier = CardIdentifier('PokemonCards/cardAttributes/cardAttributes.csv')
result = identifier.identify_card('PokemonCards/testImage/test.jpg')
