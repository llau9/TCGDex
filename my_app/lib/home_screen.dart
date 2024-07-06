import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_page.dart';
import 'portfolio_page.dart';
import 'camera_page.dart';
import 'social_page.dart';
import 'settings_page.dart';
import 'sign_in_page.dart';
import 'market_page.dart';
import 'search_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<String> _setLogos = [];

  static final List<Widget> _widgetOptions = <Widget>[
    HomeContent(logos: []),
    const MarketPage(),
    const CameraPage(),
    const PortfolioPage(),
    const SocialPage(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchAllSetLogos();
  }

  Future<void> _fetchAllSetLogos() async {
    const platform = MethodChannel('com.example/tcgdex');
    try {
      final List<dynamic> logos = await platform.invokeMethod('fetchAllSetLogos');
      print("Fetched logos from platform: $logos");
      setState(() {
        _setLogos = logos.cast<String>();
      });
      print("Updated state with logos: $_setLogos");
    } on PlatformException catch (e) {
      print("Failed to fetch set logos: '${e.message}'.");
    } catch (e) {
      print("Unknown error occurred while fetching set logos: '$e'.");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    List<Widget> _widgetOptionsWithLogos = <Widget>[
      HomeContent(logos: _setLogos),
      const MarketPage(),
      const CameraPage(),
      const PortfolioPage(),
      const SocialPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('TCGDex'),
        leading: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            );
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
                color: Color(0xFFFF6961),
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
            if (user == null)
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Sign In'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInPage()),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: _widgetOptionsWithLogos.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Social',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFFFFC1C1),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final List<String> logos;

  const HomeContent({Key? key, required this.logos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("Building HomeContent. Logos: $logos");
    if (logos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 1, // Adjust based on your image aspect ratio
      ),
      itemCount: logos.length,
      itemBuilder: (context, index) {
        final String imageUrl = logos[index];
        return HomeCard(imageUrl: imageUrl);
      },
    );
  }
}

class HomeCard extends StatelessWidget {
  final String imageUrl;

  const HomeCard({required this.imageUrl, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 4.0,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Text('Error loading image'));
              },
            ),
          ),
        ),
      ),
    );
  }
}
