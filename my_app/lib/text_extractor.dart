import 'dart:convert';
import 'dart:typed_data';
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:http/http.dart' as http;

class TextExtractor {
  final String apiKey;

  TextExtractor({required this.apiKey});

  Future<http.Response> _postRequestWithApiKey(vision.BatchAnnotateImagesRequest request) {
    final uri = Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$apiKey');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(request.toJson());
    return http.post(uri, headers: headers, body: body);
  }

  Future<String> _extractTextFromImage(Uint8List imageBytes) async {
    final visionRequest = vision.AnnotateImageRequest(
      image: vision.Image(content: base64Encode(imageBytes)),
      features: [vision.Feature(type: 'TEXT_DETECTION')],
    );
    final visionBatchRequest = vision.BatchAnnotateImagesRequest(requests: [visionRequest]);

    final response = await _postRequestWithApiKey(visionBatchRequest);

    if (response.statusCode == 200) {
      final visionBatchResponse = vision.BatchAnnotateImagesResponse.fromJson(jsonDecode(response.body));
      final textAnnotations = visionBatchResponse.responses?.first.textAnnotations;
      if (textAnnotations != null && textAnnotations.isNotEmpty) {
        return textAnnotations.first.description ?? '';
      } else {
        return '';
      }
    } else {
      throw Exception('Failed to extract text from image: ${response.body}');
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