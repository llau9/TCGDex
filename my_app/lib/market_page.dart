import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'profile_page.dart';
import 'cart_page.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  _MarketPageState createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  static const platform = MethodChannel('com.example/tcgdex');
  late Future<List<String>> wishlistImages;
  late Future<List<String>> storefrontImages;

  @override
  void initState() {
    super.initState();
    wishlistImages = fetchRandomCardImages(4); // Fetch 4 images for the wishlist
    storefrontImages = fetchRandomCardImages(4); // Fetch 4 images for the storefront
  }

  Future<List<String>> fetchRandomCardImages(int count) async {
    List<String> images = [];
    try {
      for (int i = 0; i < count; i++) {
        final String result = await platform.invokeMethod('fetchRandomCardImage');
        images.add(result);
        print("Fetched card image URL: $result");
      }
    } on PlatformException catch (e) {
      print("Failed to fetch random card image: '${e.message}'.");
    }
    return images;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color:Color(0xFFFF6961),
              ),
              child: Text(
                'Account Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                // Handle settings action
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                // Handle sign out action
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
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
            FutureBuilder<List<String>>(
              future: wishlistImages,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No card images found');
                }
                final images = snapshot.data!;
                return SizedBox(
                  height: 150.0,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: images.map((image) => WishlistCard(imageUrl: image)).toList(),
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
              child: FutureBuilder<List<String>>(
                future: storefrontImages,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No card images found');
                  }
                  final images = snapshot.data!;
                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    children: images.map((image) => StorefrontCard(imageUrl: image)).toList(),
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

class WishlistCard extends StatelessWidget {
  final String imageUrl;

  const WishlistCard({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: AspectRatio(
          aspectRatio: 63 / 88, // Aspect ratio for standard card dimensions
          child: imageUrl.isNotEmpty
              ? Image.network(imageUrl, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Text('Error loading image'));
                })
              : const Center(child: Text('No image URL')),
        ),
      ),
    );
  }
}

class StorefrontCard extends StatelessWidget {
  final String imageUrl;

  const StorefrontCard({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AspectRatio(
          aspectRatio: 63 / 88, // Aspect ratio for standard card dimensions
          child: imageUrl.isNotEmpty
              ? Image.network(imageUrl, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Text('Error loading image'));
                })
              : const Center(child: Text('No image URL')),
        ),
      ),
    );
  }
}
