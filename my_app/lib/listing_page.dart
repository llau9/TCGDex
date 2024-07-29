import 'package:flutter/services.dart';

class ImageProcessor {
  static const MethodChannel _channel = MethodChannel('com.example/tcgdex');

  static Future<List<Map<String, int>>> preprocessImage(String imagePath) async {
    try {
      final List<dynamic> regionSizes = await _channel.invokeMethod('preprocessImage', {'imagePath': imagePath});
      return regionSizes.map((region) => Map<String, int>.from(region)).toList();
    } on PlatformException catch (e) {
      print("Failed to preprocess image: ${e.message}");
      return [];
    }
  }
}
