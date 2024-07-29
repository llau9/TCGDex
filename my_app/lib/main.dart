import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'text_extractor.dart'; // Ensure this path is correct

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from the .env file
  await dotenv.load(fileName: ".env");

  // Retrieve environment variables from the dotenv package
  final homeEnv = dotenv.env['HOME'];
  final googleCredsEnv = dotenv.env['GOOGLE_APPLICATION_CREDENTIALS'];

  // Check if environment variables are set
  if (homeEnv == null || googleCredsEnv == null) {
    print('Environment variables are not set correctly.');
    print('HOME: $homeEnv');
    print('GOOGLE_APPLICATION_CREDENTIALS: $googleCredsEnv');
    return;
  }

  // Replace with your Google Cloud Vision API key
  const apiKey = 'AIzaSyBU-p3eA5Sxm5Xb5JssbvCDD7k96uIxXFA';

  // Initialize the TextExtractor
  final textExtractor = TextExtractor(apiKey: apiKey);

  // Load an image file to test the text extraction from assets
  final ByteData data = await rootBundle.load('assets/downloaded_images/base3-1.png');
  final Uint8List imageBytes = data.buffer.asUint8List();

  // Test extracting text from the image
  try {
    final extractedText = await textExtractor.extractTextFromName(imageBytes);
    print('Extracted Text: $extractedText');
  } catch (e) {
    print('Error extracting text from name: $e');
  }

  // Test extracting HP from the image
  try {
    final extractedHp = await textExtractor.extractTextFromHp(imageBytes);
    print('Extracted HP: $extractedHp');
  } catch (e) {
    print('Error extracting text from HP: $e');
  }

  // Test extracting moves from the image
  try {
    final extractedMoves = await textExtractor.extractTextFromMoves(imageBytes);
    print('Extracted Moves: $extractedMoves');
  } catch (e) {
    print('Error extracting text from moves: $e');
  }

  // Run the Flutter app (if necessary)
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Text Extractor Test'),
        ),
        body: Center(
          child: Text('Check the console for test results.'),
        ),
      ),
    );
  }
}