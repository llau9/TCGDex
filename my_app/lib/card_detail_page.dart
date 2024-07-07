import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CardDetailPage extends StatelessWidget {
  final String cardId;
  final String imageUrl;
  final Map<String, String> cardDetails;

  const CardDetailPage({
    Key? key,
    required this.cardId,
    required this.imageUrl,
    required this.cardDetails,
  }) : super(key: key);

  Future<void> addToPortfolio(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      CollectionReference portfolio = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('portfolio');

      try {
        await portfolio.add({
          'cardId': cardId,
          'timestamp': FieldValue.serverTimestamp(),
          // Add more fields as needed
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Card added to your portfolio'),
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to add card: $e'),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('You need to be signed in to add cards to your portfolio'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Card Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Text('Error loading image'));
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              cardId,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: cardDetails.length,
              itemBuilder: (context, index) {
                String key = cardDetails.keys.elementAt(index);
                return ListTile(
                  title: Text(key),
                  subtitle: Text(cardDetails[key]!),
                );
              },
            ),
            const SizedBox(height: 16),
            // Add to Portfolio Button
            Center(
              child: ElevatedButton(
                onPressed: () => addToPortfolio(context),
                child: const Text('Add to Portfolio'),
              ),
            ),
            const SizedBox(height: 16),
            // Placeholder for additional details
            Text(
              'Additional Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: Text('Market Price'),
              subtitle: Text('Fetching data...'),
            ),
            ListTile(
              title: Text('Price History'),
              subtitle: Text('Fetching data...'),
            ),
            ListTile(
              title: Text('Latest Sales'),
              subtitle: Text('Fetching data...'),
            ),
            ListTile(
              title: Text('Other Listings'),
              subtitle: Text('Fetching data...'),
            ),
          ],
        ),
      ),
    );
  }
}