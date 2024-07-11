import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;
  String? _imagePath;
  String? _cardId;
  Map<String, dynamic>? _cardDetails;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _controller.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture(BuildContext context) async {
    try {
      await _initializeControllerFuture;

      final directory = await getTemporaryDirectory();
      final path = join(
        directory.path,
        '${DateTime.now()}.png',
      );

      final image = await _controller.takePicture();
      await image.saveTo(path);

      setState(() {
        _imagePath = path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Picture taken!')),
      );

      final cardDetails = await _uploadImage(File(path));

      setState(() {
        _cardDetails = cardDetails;
      });

    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<Map<String, dynamic>?> _uploadImage(File image) async {
    final url = Uri.parse('http://your_server_ip:5000/identify'); // Update with your server IP
    final request = http.MultipartRequest('POST', url)
      ..files.add(await http.MultipartFile.fromPath('image', image.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await http.Response.fromStream(response);
      final data = jsonDecode(responseData.body);
      return data;
    } else {
      print('Failed to identify card');
      return null;
    }
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });

      final cardDetails = await _uploadImage(File(pickedFile.path));

      setState(() {
        _cardDetails = cardDetails;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return _imagePath == null
                ? CameraPreview(_controller)
                : ImagePreview(imagePath: _imagePath!, cardDetails: _cardDetails);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            child: const Icon(Icons.camera),
            onPressed: () => _takePicture(context),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            child: const Icon(Icons.photo),
            onPressed: () => _pickImageFromGallery(context),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class ImagePreview extends StatelessWidget {
  final String imagePath;
  final Map<String, dynamic>? cardDetails;

  const ImagePreview({super.key, required this.imagePath, this.cardDetails});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Image.file(File(imagePath)),
        ),
        if (cardDetails != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Card Details: ${cardDetails.toString()}'),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Retake'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (cardDetails != null) {
                    fetchCardDetails(cardDetails!['id'], context);
                  }
                },
                child: const Text('Use this photo'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void fetchCardDetails(String cardId, BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => CardDetailPage(cardId: cardId),
    ));
  }
}

class CardDetailPage extends StatelessWidget {
  final String cardId;

  const CardDetailPage({super.key, required this.cardId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Card Details'),
      ),
      body: Center(
        child: Text('Card ID: $cardId'),
      ),
    );
  }
}
