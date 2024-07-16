import 'dart:io';
import 'package:flutter/material.dart';

class ProcessedImagePage extends StatelessWidget {
  final String imagePath;
  final Map<String, dynamic>? processedImageDetails;

  const ProcessedImagePage({
    Key? key,
    required this.imagePath,
    this.processedImageDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processed Image'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Image.file(File(imagePath)),
                if (processedImageDetails != null && processedImageDetails!['regions'] != null)
                  ...processedImageDetails!['regions'].map<Widget>((region) {
                    return Positioned(
                      left: region['x'].toDouble(),
                      top: region['y'].toDouble(),
                      width: region['width'].toDouble(),
                      height: region['height'].toDouble(),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
          if (processedImageDetails != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Processed Image Details: ${processedImageDetails.toString()}'),
            ),
        ],
      ),
    );
  }
}
