import os
import csv
import json
import requests
from PIL import Image
from io import BytesIO

class ImageDownloader:
    def __init__(self, dataset_path, download_dir='PokemonCards/downloaded_images'):
        self.dataset_path = dataset_path
        self.download_dir = download_dir
        os.makedirs(self.download_dir, exist_ok=True)

    def download_image(self, url, image_id):
        try:
            # print(f"Attempting to download image {image_id} from {url}")
            response = requests.get(url, timeout=20)
            response.raise_for_status()
            image = Image.open(BytesIO(response.content))
            image_path = os.path.join(self.download_dir, f"{image_id}.png")
            image.save(image_path)
            # print(f"Successfully downloaded {image_id}")
            return image_path
        except requests.RequestException as e:
            print(f"Error downloading {url}: {e}")
            return None

    def load_dataset_images(self, max_images=17000):
        dataset_file_path = os.path.join(self.download_dir, 'dataset.json')
        existing_dataset = []

        # Load existing dataset if it exists
        if os.path.exists(dataset_file_path):
            with open(dataset_file_path, 'r') as file:
                existing_dataset = json.load(file)

        with open(self.dataset_path, 'r') as file:
            reader = csv.DictReader(file)
            for row in reader:
                image_path = self.download_image(row['image_url'], row['id'])
                if image_path:
                    image_data = {
                        'id': row['id'],
                        'image_path': image_path,
                        'caption': row['caption'],
                        'name': row['name'],
                        'hp': row['hp'],
                        'set_name': row['set_name']
                    }
                    existing_dataset.append(image_data)
                if max_images and len(existing_dataset) >= max_images:
                    break

        # Save the updated dataset
        with open(dataset_file_path, 'w') as file:
            json.dump(existing_dataset, file)

        return existing_dataset