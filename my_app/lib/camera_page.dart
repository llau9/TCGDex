import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'text_extractor.dart';
import 'processed_image_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;
  String? _imagePath;
  Map<String, dynamic>? _cardDetails;
  final TextExtractor _textExtractor = TextExtractor(apiKey: 'AIzaSyBU-p3eA5Sxm5Xb5JssbvCDD7k96uIxXFA'); // Replace with your actual API key

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

      await _cropImage(context, path);

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

      await _cropImage(context, pickedFile.path);

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected.')),
      );
    }
  }

  Future<void> _cropImage(BuildContext context, String path) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          minimumAspectRatio: 1.0,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _imagePath = croppedFile.path;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image not cropped.')),
      );
    }
  }

  Future<void> _processCroppedImage(BuildContext context) async {
    if (_imagePath != null) {
      final processedImageDetails = await _processImage(File(_imagePath!));

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
        const SnackBar(content: Text('No image selected for processing.')),
      );
    }
  }

  Future<Map<String, dynamic>?> _processImage(File image) async {
    try {
      final imageBytes = await image.readAsBytes();

      final extractedText = await _textExtractor.extractTextFromName(imageBytes);
      final extractedHp = await _textExtractor.extractTextFromHp(imageBytes);
      final extractedMoves = await _textExtractor.extractTextFromMoves(imageBytes);

      return {
        'name': extractedText,
        'hp': extractedHp,
        'moves': extractedMoves,
        'imagePath': image.path,
      };
    } catch (e) {
      print('Error processing image: $e');
      return null;
    }
  }

  void _retakePicture() {
    setState(() {
      _imagePath = null;
    });
    _initializeCamera(); // Reinitialize the camera when retaking a picture
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return _imagePath == null
                ? Stack(
                    children: [
                      CameraPreview(_controller),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 30.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.photo, color: Colors.white, size: 30),
                                onPressed: () => _pickImageFromGallery(context),
                              ),
                              FloatingActionButton(
                                onPressed: () => _takePicture(context),
                                backgroundColor: Colors.red,
                                shape: CircleBorder(
                                  side: BorderSide(color: Colors.white, width: 4),
                                ),
                                child: const Icon(Icons.camera, color: Colors.white, size: 30),
                              ),
                              IconButton(
                                icon: const Icon(Icons.flash_on, color: Colors.white, size: 30),
                                onPressed: () {
                                  // Toggle flash logic
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ImagePreview(
                    imagePath: _imagePath!,
                    cardDetails: _cardDetails,
                    onProcess: () => _processCroppedImage(context),
                    onRetake: _retakePicture,
                  );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class ImagePreview extends StatelessWidget {
  final String imagePath;
  final Map<String, dynamic>? cardDetails;
  final VoidCallback onProcess;
  final VoidCallback onRetake;

  const ImagePreview({
    super.key,
    required this.imagePath,
    this.cardDetails,
    required this.onProcess,
    required this.onRetake,
  });

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
                onPressed: onRetake,
                child: const Text('Retake'),
              ),
              ElevatedButton(
                onPressed: onProcess,
                child: const Text('Proceed'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
