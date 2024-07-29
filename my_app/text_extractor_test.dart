import 'dart:io';
import 'dart:typed_data';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:http/http.dart' as http;
import 'lib/text_extractor.dart'; // Make sure this path is correct

void main() async {
  // Replace with your Google Cloud Vision API key
  const apiKey = 'AIzaSyBU-p3eA5Sxm5Xb5JssbvCDD7k96uIxXFA';

  // Initialize the TextExtractor with the API key
  final textExtractor = TextExtractor(apiKey);

  // Load an image file to test the text extraction
  final imageFile = File('path_to_your_image.jpg'); // Replace with the path to your image file
  final imageBytes = await imageFile.readAsBytes();

  // Test extracting text from the image
  final extractedText = await textExtractor.extractTextFromName(Uint8List.fromList(imageBytes));
  print('Extracted Text: $extractedText');

  // Test extracting HP from the image
  final extractedHp = await textExtractor.extractTextFromHp(Uint8List.fromList(imageBytes));
  print('Extracted HP: $extractedHp');

  // Test extracting moves from the image
  final extractedMoves = await textExtractor.extractTextFromMoves(Uint8List.fromList(imageBytes));
  print('Extracted Moves: $extractedMoves');
}