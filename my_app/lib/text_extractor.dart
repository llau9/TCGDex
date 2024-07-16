import 'dart:convert';
import 'dart:typed_data';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:http/http.dart' as http;

class TextExtractor {
  static const _scopes = [vision.VisionApi.cloudVisionScope];
  final String _apiKey;

  TextExtractor(this._apiKey);

  Future<vision.VisionApi> _initializeVisionApi() async {
    var client = http.Client();
    return vision.VisionApi(client);
  }

  Future<String> _extractTextFromImage(Uint8List imageBytes) async {
    final visionApi = await _initializeVisionApi();
    final visionRequest = vision.AnnotateImageRequest(
      image: vision.Image(content: base64Encode(imageBytes)),
      features: [vision.Feature(type: 'TEXT_DETECTION')],
    );
    final visionBatchRequest = vision.BatchAnnotateImagesRequest(requests: [visionRequest]);
    final visionBatchResponse = await visionApi.images.annotate(visionBatchRequest);

    final textAnnotations = visionBatchResponse.responses?.first.textAnnotations;
    if (textAnnotations != null && textAnnotations.isNotEmpty) {
      return textAnnotations.first.description ?? '';
    } else {
      return '';
    }
  }

  Future<String> extractTextFromName(Uint8List imageBytes) async {
    return await _extractTextFromImage(imageBytes);
  }

  Future<String> extractTextFromHp(Uint8List imageBytes) async {
    final text = await _extractTextFromImage(imageBytes);
    return _postProcessHpText(text);
  }

  Future<String> extractTextFromMoves(Uint8List imageBytes) async {
    return await _extractTextFromImage(imageBytes);
  }

  String _postProcessHpText(String hpText) {
    hpText = hpText.replaceAll(RegExp(r'[Oo]'), '0').replaceAll('B', '8').replaceAll(RegExp(r'[lI]'), '1');
    hpText = hpText.replaceAll(RegExp(r'[^0-9]'), '');
    if (hpText.length > 3) {
      hpText = hpText.startsWith('1') ? hpText.substring(0, 3) : hpText.substring(0, 2);
    }
    return hpText;
  }

  String _postProcessText(String text) {
    final corrections = {
      '0': 'O',
      '1': 'I',
      '5': 'S',
      '8': 'B',
    };
    corrections.forEach((wrong, correct) {
      text = text.replaceAll(wrong, correct);
    });
    text = text.replaceAll(RegExp(r'[^a-zA-Z\s]'), '');
    return text;
  }
}