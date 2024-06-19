from data_processor import ImageDownloader
from image_processor import ImagePreprocessor
from text_extractor2 import TextExtractor
import cv2
import matplotlib.pyplot as plt
#from sklearn.model_selection import train_test_split
#from sklearn.ensemble import RandomForestClassifier
#from sklearn.metrics import classification_report

downloader = ImageDownloader('PokemonCards/train.csv')
preprocessor = ImagePreprocessor()
textExtractor = TextExtractor()

images = downloader.load_dataset_images()

# Check the number of images downloaded
print(f"Number of images downloaded: {len(images)}")

# Optionally, display one of the images to ensure it's downloaded correctly

# Check the number of images downloaded and ensure at least one is available
if len(images) > 0:
    image_info = images[20]  # Get the first image information
    image_path = image_info['image_path']  # Extract the path of the downloaded image

    # Process the image to isolate regions
    processed_image, name_region, hp_region, move_region = preprocessor.isolate_regions(image_path)

    # Display the processed image with defined regions
    plt.figure(figsize=(10, 10))
    plt.imshow(cv2.cvtColor(hp_region, cv2.COLOR_BGR2RGB))  # Convert BGR to RGB for displaying
    plt.title('Processed Image with Defined Regions')
    plt.show()

    name = textExtractor.extract_text_from_name(name_region)
    hp = textExtractor.extract_text_from_hp(hp_region)
    moves = textExtractor.extract_text_from_moves(move_region)

    print("Extracted Name Text:", textExtractor.post_process_text(name))
    print("Extracted HP Text:", textExtractor.post_process_hp_text(hp))
    print("Extracted MoveText:", textExtractor.post_process_text(moves))

else:
    print("No images were downloaded.")


