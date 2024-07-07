import 'package:flutter/material.dart';

class ListingPage extends StatelessWidget {
  final String imageUrl;

  const ListingPage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Listing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 63 / 88,
                child: Image.network(imageUrl, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Text('Error loading image'));
                }),
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Scizor - WoTC Black Star Promo #33',
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Condition: Lightly Played (Excellent)',
              style: TextStyle(
                fontSize: 18.0,
              ),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Price: \$5.99',
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Handle buy action
              },
              child: const Text('Buy Now'),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle add to cart action
              },
              child: const Text('Add to Cart'),
            ),
          ],
        ),
      ),
    );
  }
}
