import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CardDetailPage extends StatefulWidget {
  final String cardId;
  final String imageUrl;
  final Map<String, String> cardDetails;

  const CardDetailPage({
    super.key,
    required this.cardId,
    required this.imageUrl,
    required this.cardDetails,
  });

  @override
  _CardDetailPageState createState() => _CardDetailPageState();
}

class _CardDetailPageState extends State<CardDetailPage> {
  bool isInPortfolio = false;
  bool isInWishlist = false;
  int duplicateCount = 1;
  final TextEditingController duplicateController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkCardStatus();
  }

  Future<void> checkCardStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('portfolio')
          .doc(widget.cardId)
          .get();
      setState(() {
        isInPortfolio = doc.exists;
        if (isInPortfolio) {
          duplicateCount = doc['duplicateCount'] ?? 1;
          duplicateController.text = duplicateCount.toString();
        }
      });

      DocumentSnapshot wishlistDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc(widget.cardId)
          .get();
      setState(() {
        isInWishlist = wishlistDoc.exists;
        isLoading = false;
      });
    }
  }

  Future<void> togglePortfolioStatus(BuildContext context, bool value) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('portfolio')
          .doc(widget.cardId);

      try {
        if (value) {
          await docRef.set({
            'cardId': widget.cardId,
            'timestamp': FieldValue.serverTimestamp(),
            'duplicateCount': duplicateCount,
            'isInWishlist': isInWishlist,
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Card added to your portfolio'),
          ));
        } else {
          await docRef.delete();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Card removed from your portfolio'),
          ));
        }
        setState(() {
          isInPortfolio = value;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update portfolio: $e'),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You need to be signed in to update your portfolio'),
      ));
    }
  }

  Future<void> toggleWishlistStatus(BuildContext context, bool value) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference wishlistDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .doc(widget.cardId);

      try {
        if (value) {
          await wishlistDocRef.set({
            'cardId': widget.cardId,
            'timestamp': FieldValue.serverTimestamp(),
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Card added to your wishlist'),
          ));
        } else {
          await wishlistDocRef.delete();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Card removed from your wishlist'),
          ));
        }
        setState(() {
          isInWishlist = value;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update wishlist: $e'),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You need to be signed in to update your wishlist'),
      ));
    }
  }

  Future<void> updateDuplicateCount(String value) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && isInPortfolio) {
      int newCount = int.tryParse(value) ?? 1;
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('portfolio')
          .doc(widget.cardId);

      try {
        await docRef.update({
          'duplicateCount': newCount,
        });
        setState(() {
          duplicateCount = newCount;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Number of cards updated'),
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update number of cards: $e'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Details'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Text('Error loading image'));
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.cardId,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.cardDetails.length,
                    itemBuilder: (context, index) {
                      String key = widget.cardDetails.keys.elementAt(index);
                      return ListTile(
                        title: Text(key),
                        subtitle: Text(widget.cardDetails[key]!),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Add to Portfolio Switch
                  SwitchListTile(
                    title: const Text('Add/Remove to Portfolio'),
                    value: isInPortfolio,
                    onChanged: (value) => togglePortfolioStatus(context, value),
                  ),
                  const SizedBox(height: 16),
                  // Number of Cards TextField
                  if (isInPortfolio)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Number of Cards',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextField(
                          controller: duplicateController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            updateDuplicateCount(value);
                          },
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  // Wishlist Switch
                  SwitchListTile(
                    title: const Text('Add/Remove to Wishlist'),
                    value: isInWishlist,
                    onChanged: (value) => toggleWishlistStatus(context, value),
                  ),
                  const SizedBox(height: 16),
                  // Placeholder for additional details
                  const Text(
                    'Additional Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const ListTile(
                    title: Text('Market Price'),
                    subtitle: Text('Fetching data...'),
                  ),
                  const ListTile(
                    title: Text('Price History'),
                    subtitle: Text('Fetching data...'),
                  ),
                  const ListTile(
                    title: Text('Latest Sales'),
                    subtitle: Text('Fetching data...'),
                  ),
                  const ListTile(
                    title: Text('Other Listings'),
                    subtitle: Text('Fetching data...'),
                  ),
                ],
              ),
            ),
    );
  }
}