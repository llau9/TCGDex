import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:convert';
import 'auth_service.dart';
import 'profile_page.dart';
import 'cart_page.dart';
import 'listing_page.dart';
import 'package:url_launcher/url_launcher.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  _MarketPageState createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final MarketService marketService = MarketService();
  late Future<List<Map<String, dynamic>>> storefrontListings;
  final StreamController<List<Map<String, dynamic>>> _wishlistListingsController = StreamController<List<Map<String, dynamic>>>();
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    storefrontListings = marketService.fetchEbayListings("pokemon cards storefront"); // Example query for storefront
    _fetchWishlistListings();
  }

  @override
  void dispose() {
    _wishlistListingsController.close();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchWishlistListings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .snapshots()
          .listen((snapshot) async {
        List<Map<String, dynamic>> listings = [];
        for (var doc in snapshot.docs) {
          final String cardName = doc.get('name');
          final String cardImageUrl = doc.get('imageUrl'); // Assuming imageUrl is stored in Firestore
          final String cardId = doc.id;
          final List<Map<String, dynamic>> ebayListings = await marketService.fetchEbayListings(cardName);
          listings.addAll(ebayListings.map((listing) {
            listing['cardImageUrl'] = cardImageUrl;
            listing['cardId'] = cardId;
            return listing;
          }));
        }
        _wishlistListingsController.add(listings);
      });
    }
  }

  void _onSearch() async {
    setState(() {
      isLoading = true;
    });

    final query = searchController.text;
    final searchResults = await marketService.fetchEbayListings(query);

    setState(() {
      storefrontListings = Future.value(searchResults);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: isLoading ? CircularProgressIndicator() : const Icon(Icons.search),
                  onPressed: _onSearch,
                ),
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CartPage()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Wishlist / Needed Cards for Collection',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _wishlistListingsController.stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No card listings found');
                }
                final listings = snapshot.data!;
                return SizedBox(
                  height: 150.0,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: listings.map((listing) => CardImageCard(listing: listing, marketService: marketService)).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Featured Sponsored Storefronts',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: storefrontListings,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No storefront listings found');
                  }
                  final listings = snapshot.data!;
                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    children: listings.map((listing) => ListingCard(listing: listing)).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardImageCard extends StatelessWidget {
  final Map<String, dynamic> listing;
  final MarketService marketService;

  const CardImageCard({super.key, required this.listing, required this.marketService});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final ebayListingUrl = listing['itemWebUrl'];
        if (await canLaunch(ebayListingUrl)) {
          await launch(ebayListingUrl);
        } else {
          throw 'Could not launch $ebayListingUrl';
        }
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 63 / 88, // Aspect ratio for standard card dimensions
                child: listing['cardImageUrl'] != null
                    ? Image.network(listing['cardImageUrl'], fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Text('Error loading image'));
                      })
                    : const Center(child: Text('No image URL')),
              ),
              const SizedBox(height: 8.0),
              Text(
                listing['title'],
                style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4.0),
              Text(
                '\$${listing['price']['value']}',
                style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ListingCard extends StatelessWidget {
  final Map<String, dynamic> listing;

  const ListingCard({Key? key, required this.listing}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListingPage(imageUrl: listing['image']['imageUrl']),
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 63 / 88, // Aspect ratio for standard card dimensions
                child: listing['image']['imageUrl'] != null
                    ? Image.network(listing['image']['imageUrl'], fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Text('Error loading image'));
                      })
                    : const Center(child: Text('No image URL')),
              ),
              const SizedBox(height: 8.0),
              Text(
                listing['title'],
                style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4.0),
              Text(
                '\$${listing['price']['value']}',
                style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}