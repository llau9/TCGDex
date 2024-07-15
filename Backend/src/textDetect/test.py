from data_processor import ImageDownloader
from image_processor import ImagePreprocessor
import cv2
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report

downloader = ImageDownloader('/train.csv')
preprocessor = ImagePreprocessor()

images = downloader.load_dataset_images()

# Check the number of images downloaded
print(f"Number of images downloaded: {len(images)}")


