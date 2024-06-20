from yolov5 import YOLOv5Model, CardDetector
from data_processor import ImageDownloader
from image_processor import ImagePreprocessor
from text_extractor2 import TextExtractor
import cv2
import matplotlib.pyplot as plt
#from sklearn.model_selection import train_test_split
#from sklearn.ensemble import RandomForestClassifier
#from sklearn.metrics import classification_report

def main():
    # Initialize the downloader
    downloader = ImageDownloader('PokemonCards/train.csv')

    # Initialize YOLOv5 model
    yolov5_model = YOLOv5Model(model_path='yolov5s.pt')

    # Initialize CardDetector with YOLOv5 model
    detector = CardDetector(model=yolov5_model, dataset_path='PokemonCards/train.csv')

    # Download images
    images = downloader.load_dataset_images()

    # Check the number of images downloaded
    print(f"Number of images downloaded: {len(images)}")

    # Optionally, display one of the images to ensure it's downloaded correctly
    if len(images) > 0:
        image_info = images[0]  # Get the first image information
        image_path = image_info['image_path']  # Extract the path of the downloaded image

        # Run detection using YOLOv5
        results = detector.detect_cards(image_path)

        # Visualize detections
        detector.visualize_detections(image_path, results)
    else:
        print("No images were downloaded.")

if __name__ == "__main__":
    main()