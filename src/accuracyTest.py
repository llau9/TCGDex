import json
import pandas as pd
from fuzzywuzzy import fuzz, process
from image_processor import ImagePreprocessor
from text_extractor2 import TextExtractor
import matplotlib.pyplot as plt
import ast
import cv2 

class CardMatcher:

    def __init__(self, card_attributes_path, image_dataset_path, match_threshold=70):
        self.card_attributes_path = card_attributes_path
        self.image_dataset_path = image_dataset_path
        self.match_threshold = match_threshold
        self.card_attributes = self.load_card_attributes()
        self.image_dataset = self.load_image_dataset()

    def load_card_attributes(self):
        data = pd.read_csv(self.card_attributes_path)
        list_dict_fields = ['types', 'subtypes', 'evolvesTo', 'abilities', 'attacks', 'weaknesses', 'retreatCost', 'nationalPokedexNumbers', 'resistances', 'rules']
        for field in list_dict_fields:
            data[field] = data[field].apply(lambda x: ast.literal_eval(x) if pd.notna(x) else None)
        return data

    def load_image_dataset(self):
        with open(self.image_dataset_path, 'r') as file:
            data = json.load(file)
        return pd.DataFrame(data)

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

        # plt.figure(figsize=(10, 10))
        # plt.imshow(processed_image, cmap='gray')  # Display the image in grayscale
        # plt.title('Processed Image with Defined Regions')
        # plt.show()

        # Extract text
        ocr_name = TextExtractor.extract_text_from_name(name_region)
        ocr_hp = TextExtractor.extract_text_from_hp(hp_region)
        ocr_moves = TextExtractor.extract_text_from_moves(moves_region)

        # Post-process text
        ocr_name = TextExtractor.post_process_text(ocr_name)
        ocr_hp = TextExtractor.post_process_hp_text(ocr_hp)

        # print("Extracted Name Text:", ocr_name)
        # print("Extracted HP Text:", ocr_hp)
        # print("Extracted MoveText:", ocr_moves)


        # Match against the card attributes
        for index, card in self.card_attributes.iterrows():  # Fixed reference to the correct dataset

            name_match = self.match_text(ocr_name, card['name'])
            hp_match = self.match_text(ocr_hp, str(card['hp']))
            moves_match = self.compare_attacks_abilities(ocr_moves, card)

            if name_match and hp_match and moves_match:
                return card  # Return the matching card

        return None  # Return None if no match found
    
    
    def validate_cards(self, max_images=None):
        preprocessor = ImagePreprocessor()
        total_matches = 0
        results = []

        # If max_images is specified, limit the number of images processed
        image_data_subset = self.image_dataset.head(max_images) if max_images else self.image_dataset

        for index, data in image_data_subset.iterrows():
            image_path = data['image_path']

            card = self.identify_card(image_path)
            if card is not None:
                total_matches += 1
                results.append({
                    'image_path': image_path,
                    'card_id': card['id'],
                    'name': card['name'],
                    # Add other details as necessary
                })
                print(f"Identified Card: {card['name']} (ID: {card['id']})")

        print(f"Total Matches: {total_matches}")
        return results

    def run(self, max_images=None):
        self.validate_cards(max_images)

# Example usage
identifier = CardMatcher('PokemonCards/cardAttributes/cardAttributes.csv', 'PokemonCards/downloaded_images/dataset.json')
# Specify how many images you want to test, for example, 10
identifier.run(max_images=100)