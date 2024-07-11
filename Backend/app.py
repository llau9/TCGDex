from flask import Flask, request, jsonify
import pandas as pd
import cv2
import json
import os
from skimage.transform import hough_line, hough_line_peaks
from fuzzywuzzy import fuzz, process
from textDetect.image_processor import ImagePreprocessor
from textDetect.text_extractor2 import TextExtractor
import matplotlib.pyplot as plt
import ast

app = Flask(__name__)

class CardIdentifier:
    def __init__(self, dataset_path, match_threshold=90):
        self.dataset_path = dataset_path
        self.match_threshold = match_threshold
        self.dataset = self.load_data()

    def load_data(self):
        data = pd.read_csv(self.dataset_path)
        list_dict_fields = ['types', 'subtypes', 'evolvesTo', 'abilities', 'attacks', 'weaknesses', 'retreatCost', 'nationalPokedexNumbers', 'resistances', 'rules']
        for field in list_dict_fields:
            data[field] = data[field].apply(lambda x: ast.literal_eval(x) if pd.notna(x) else None)
        return data

    def match_text(self, extracted_text, actual_text):
        if extracted_text and actual_text:
            match = process.extractOne(extracted_text, [actual_text], scorer=fuzz.partial_ratio, score_cutoff=self.match_threshold)
            return match is not None
        return False

    def compare_attacks_abilities(self, ocr_text, card_data):
        possible_matches = []
        for attack in card_data['attacks'] if card_data['attacks'] is not None else []:
            if 'name' in attack and isinstance(attack['name'], str) and self.match_text(ocr_text, attack['name']):
                possible_matches.append(attack)
            if 'text' in attack and isinstance(attack['text'], str) and self.match_text(ocr_text, attack['text']):
                possible_matches.append(attack)

        for ability in card_data['abilities'] if card_data['abilities'] is not None else []:
            if 'name' in ability and isinstance(ability['name'], str) and self.match_text(ocr_text, ability['name']):
                possible_matches.append(ability)
            if 'text' in ability and isinstance(ability['text'], str) and self.match_text(ocr_text, ability['text']):
                possible_matches.append(ability)

        return possible_matches

    def identify_card(self, image_path):
        preprocessor = ImagePreprocessor()
        processed_image, name_region, hp_region, moves_region = preprocessor.isolate_regions(image_path)

        ocr_name = TextExtractor.extract_text_from_name(name_region)
        ocr_hp = TextExtractor.extract_text_from_hp(hp_region)
        ocr_moves = TextExtractor.extract_text_from_moves(moves_region)

        ocr_name = TextExtractor.post_process_text(ocr_name)
        ocr_hp = TextExtractor.post_process_hp_text(ocr_hp)

        for index, card in self.dataset.iterrows():
            name_match = self.match_text(ocr_name, card['name'])
            hp_match = self.match_text(ocr_hp, str(card['hp']))
            matches = self.compare_attacks_abilities(ocr_moves, card)
            if name_match and hp_match and matches:
                return card.to_dict()

        return None

identifier = CardIdentifier('PokemonCards/cardAttributes/cardAttributes.csv')

@app.route('/identify', methods=['POST'])
def identify():
    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided'}), 400

    image_file = request.files['image']
    image_path = os.path.join('temp', image_file.filename)
    image_file.save(image_path)

    result = identifier.identify_card(image_path)
    os.remove(image_path)

    if result:
        return jsonify(result)
    else:
        return jsonify({'error': 'Card not identified'}), 404

if __name__ == '__main__':
    if not os.path.exists('temp'):
        os.makedirs('temp')
    app.run(host='0.0.0.0', port=5000)
