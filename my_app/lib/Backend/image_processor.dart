import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:opencv_dart/opencv_dart.dart' as cv;

class ImagePreprocessor {
  static List<Offset> orderPoints(List<Offset> pts) {
    List<Offset> rect = List.filled(4, Offset.zero);
    List<double> s = pts.map((p) => p.dx + p.dy).toList();
    rect[0] = pts[s.indexOf(s.reduce((a, b) => a < b ? a : b))];
    rect[2] = pts[s.indexOf(s.reduce((a, b) => a > b ? a : b))];
    List<double> diff = pts.map((p) => p.dx - p.dy).toList();
    rect[1] = pts[diff.indexOf(diff.reduce((a, b) => a < b ? a : b))];
    rect[3] = pts[diff.indexOf(diff.reduce((a, b) => a > b ? a : b))];

    // Distance calculations for side lengths
    double widthTop = (rect[1] - rect[0]).distance;
    double widthBottom = (rect[3] - rect[2]).distance;
    double heightLeft = (rect[0] - rect[3]).distance;
    double heightRight = (rect[1] - rect[2]).distance;

    // Ensure shorter sides are top and bottom
    if ((widthTop + widthBottom) > (heightLeft + heightRight)) {
      rect = [rect[3], rect[0], rect[1], rect[2]]; // Rotate points to correct
    }

    return rect;
  }

  Future<img.Image> fourPointTransform(img.Image image, List<Offset> pts) async {
    List<Offset> rect = orderPoints(pts);
    Offset tl = rect[0], tr = rect[1], br = rect[2], bl = rect[3];

    // Compute width and height of new image
    double widthA = (br - bl).distance;
    double widthB = (tr - tl).distance;
    int maxWidth = widthA > widthB ? widthA.round() : widthB.round();
    double heightA = (tr - br).distance;
    double heightB = (tl - bl).distance;
    int maxHeight = heightA > heightB ? heightA.round() : heightB.round();

    // Define destination points for perspective transform
    List<Offset> dst = [
      Offset(0, 0),
      Offset(maxWidth - 1, 0),
      Offset(maxWidth - 1, maxHeight - 1),
      Offset(0, maxHeight - 1),
    ];

    // Perform perspective transform using OpenCV
    List<Offset> srcPoints = rect.map((e) => Offset(e.dx, e.dy)).toList();
    List<Offset> dstPoints = dst.map((e) => Offset(e.dx, e.dy)).toList();

    Uint8List srcBytes = Uint8List.fromList(image.getBytes());
    var srcMat = await cv.Mat.fromImageData(srcBytes);
    var dstMat = await cv.warpPerspective(srcMat, srcPoints, dstPoints, cv.Size(maxWidth, maxHeight));

    Uint8List dstBytes = await dstMat.toImageData();
    return img.decodeImage(dstBytes);
  }

  Future<List<img.Image>> isolateRegions(File imageFile) async {
    img.Image image = img.decodeImage(imageFile.readAsBytesSync());

    // Convert to grayscale and detect edges using OpenCV
    Uint8List grayBytes = await cv.cvtColor(Uint8List.fromList(image.getBytes()), cv.ColorConversionCodes.COLOR_BGR2GRAY);
    Uint8List cannyBytes = await cv.Canny(grayBytes, 50, 200);

    // Find contours and sort by area
    List<Offset> contours = await cv.findContours(cannyBytes, cv.ContourRetrievalModes.RETR_EXTERNAL, cv.ContourApproximationModes.CHAIN_APPROX_SIMPLE);
    contours.sort((a, b) => cv.contourArea(b).compareTo(cv.contourArea(a)));

    // Get largest contour and approximate polygon
    List<Offset> largestContour = contours[0];
    List<Offset> approx = await cv.approxPolyDP(largestContour, 0.02 * cv.arcLength(largestContour, true));

    // Warp image based on polygon points
    img.Image warped = await fourPointTransform(image, approx);

    // Normalize and extract regions
    img.Image normalizedImage = img.copyResize(warped, width: 600, height: 825);

    img.Image nameRegion = img.copyCrop(normalizedImage, 5, 0, 400, 90);
    img.Image hpRegion = img.copyCrop(normalizedImage, 400, 0, 200, 90);
    img.Image moveRegion = img.copyCrop(normalizedImage, 10, 420, 580, 310);
    img.Image setSymbolRegion = img.copyCrop(normalizedImage, 10, 730, 580, 95);

    return [normalizedImage, nameRegion, hpRegion, moveRegion, setSymbolRegion];
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File _imageFile;
  List<img.Image> _regions;

  Future<void> _pickImage() async {
    // Use an image picker library to select an image
    // File image = await ImagePicker.pickImage(source: ImageSource.gallery);

    // For example purposes, let's assume the image is already picked
    File image = File('path/to/your/image.jpg');

    setState(() {
      _imageFile = image;
    });

    if (image != null) {
      ImagePreprocessor preprocessor = ImagePreprocessor();
      List<img.Image> regions = await preprocessor.isolateRegions(image);
      setState(() {
        _regions = regions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pokemon Card Scanner'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            _imageFile == null
                ? Text('No image selected.')
                : Image.file(_imageFile),
            _regions != null
                ? Column(
                    children: _regions.map((region) => Image.memory(Uint8List.fromList(img.encodePng(region)))).toList(),
                  )
                : Container(),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() => runApp(MaterialApp(home: MyHomePage()));
