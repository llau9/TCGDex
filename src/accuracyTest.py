import json
import cv2
from fuzzywuzzy import process
from data_processor import ImageDownloader
from image_processor import ImagePreprocessor
from text_extractor import TextExtractor


class CardMatcher:
    def __init__(self, dataset_path, match_threshold=85):
        self.dataset_path = dataset_path
        self.match_threshold = match_threshold

    def load_data(self):
        with open(self.dataset_path, 'r') as file:
            return json.load(file)

    def match_text(self, extracted_text, actual_text):
        if extracted_text and actual_text:
            match = process.extractOne(extracted_text, [actual_text], score_cutoff=self.match_threshold)
            return match is not None
        return False

    def validate_cards(self, dataset):
        results = []
        preprocessor = ImagePreprocessor()
        total_matches = 0
        for data in dataset[:100]:
            image_path = data['image_path']  # Ensure this is a valid path to an image file

            processed_image, name_region, hp_region, moves_region = preprocessor.isolate_regions(image_path)

            # Extract text from regions
            ocr_name = TextExtractor.extract_text_from_name(name_region)
            ocr_hp = TextExtractor.extract_text_from_hp(hp_region)
            ocr_moves = TextExtractor.extract_text_from_moves(moves_region)

            ocr_name = TextExtractor.post_process_text(ocr_name)
            ocr_hp = TextExtractor.post_process_hp_text(ocr_hp) # If you have such a method
            # ocr_moves = TextExtractor.post_process_text(ocr_moves)

            # Perform fuzzy matching
            name_match = self.match_text(ocr_name, data['name'])
            hp_match = self.match_text(ocr_hp, data['hp'])
            moves_match = self.match_text(ocr_moves, data['caption'])

            if name_match and (hp_match or moves_match):  # All fields must match
                total_matches += 1
                results.append({
                    'image_id': data['id'],
                    'name_match': data['name'],
                    'hp_match': "YES",
                    'moves_match': "YES"
                })

        
        for result in results:
            print(f"Matched Card ID: {result['image_id']}, Name Match: {result['name_match']}, HP Match: {result['hp_match']}, Moves Match: {result['moves_match']}")

        print(f"Total Matches: {total_matches}")

        return results

    def run(self):
        dataset = self.load_data()
        self.validate_cards(dataset)

# Example usage
# Assuming 'dataset.json' is in your 'PokemonCards/downloaded_images' directory
matcher = CardMatcher('PokemonCards/downloaded_images/dataset.json')
matcher.run()