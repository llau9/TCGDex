import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'image_processor.dart'; // Make sure this path is correct
import 'processed_image_page.dart'; // Import the new page

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

      final processedImageDetails = await _processImage(File(path));

      setState(() {
        _cardDetails = processedImageDetails;
      });

      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ProcessedImagePage(
          imagePath: _imagePath!,
          processedImageDetails: _cardDetails,
        ),
      ));

    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });

      final processedImageDetails = await _processImage(File(pickedFile.path));

      setState(() {
        _cardDetails = processedImageDetails;
      });

      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ProcessedImagePage(
          imagePath: _imagePath!,
          processedImageDetails: _cardDetails,
        ),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected.')),
      );
    }
  }

  Future<Map<String, dynamic>?> _processImage(File image) async {
    final regionSizes = await ImageProcessor.preprocessImage(image.path);
    // You can transform regionSizes into a more useful format if needed
    return {
      'regions': regionSizes,
      'imagePath': image.path,
    };
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
          const SizedBox(height: 16),
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
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ProcessedImagePage(
                      imagePath: imagePath,
                      processedImageDetails: cardDetails,
                    ),
                  ));
                },
                child: const Text('Proceed'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
