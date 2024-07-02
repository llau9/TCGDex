import 'package:flutter/material.dart';
import 'profile_page.dart'; // Ensure this import is added

class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TCGDex'),
        leading: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // Handle search action
          },
        ),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
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
            TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
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
            SizedBox(
              height: 150.0,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const <Widget>[
                  WishlistCard(),
                  WishlistCard(),
                  WishlistCard(),
                  WishlistCard(),
                ],
              ),
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
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                children: const <Widget>[
                  StorefrontCard(),
                  StorefrontCard(),
                  StorefrontCard(),
                  StorefrontCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WishlistCard extends StatelessWidget {
  const WishlistCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: SizedBox(
        width: 120.0,
        child: Center(
          child: Text('Wishlist Item'),
        ),
      ),
    );
  }
}

class StorefrontCard extends StatelessWidget {
  const StorefrontCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Center(
        child: Text('Storefront Item'),
      ),
    );
  }
}
