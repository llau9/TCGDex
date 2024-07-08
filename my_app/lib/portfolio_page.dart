import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  _PortfolioPageState createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  String userName = "Anonymous";
  List<String> setSymbols = [];
  List<Map<String, dynamic>> portfolioCards = [];

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchSetSymbols();
    _fetchPortfolioCards();
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      userName = user?.displayName ?? "Anonymous";
    });
  }

  Future<void> _fetchSetSymbols() async {
    const platform = MethodChannel('com.example/tcgdex');
    try {
      final List<dynamic> result = await platform.invokeMethod('fetchAllSetSymbols');
      setState(() {
        setSymbols = result.cast<String>();
      });
    } on PlatformException catch (e) {
      print("Failed to fetch set symbols: '${e.message}'.");
    }
  }

  Future<void> _fetchPortfolioCards() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      CollectionReference portfolio = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('portfolio');

      final QuerySnapshot portfolioSnapshot = await portfolio.get();
      for (QueryDocumentSnapshot doc in portfolioSnapshot.docs) {
        final String cardId = doc['cardId'];
        await _fetchCardDetails(cardId);
      }
    }
  }

  Future<void> _fetchCardDetails(String cardId) async {
    const platform = MethodChannel('com.example/tcgdex');
    try {
      final Map<dynamic, dynamic> result = await platform.invokeMethod('fetchCardDetails', {'cardId': cardId});
      final Map<String, dynamic> cardDetails = result.map((key, value) => MapEntry(key as String, value));
      setState(() {
        portfolioCards.add(cardDetails);
      });
    } on PlatformException catch (e) {
      print("Failed to fetch card details: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileSection(userName: userName),
            SetSymbolsSection(setSymbols: setSymbols),
            CardsGridSection(cards: portfolioCards),
          ],
        ),
      ),
    );
  }
}

class ProfileSection extends StatelessWidget {
  final String userName;

  const ProfileSection({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage('assets/profile.jpg'),
          ),
          const SizedBox(width: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userName, style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
              Text('Level 12', style: TextStyle(color: Colors.grey[600])),
              Text('360/500 XP', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}

class SetSymbolsSection extends StatelessWidget {
  final List<String> setSymbols;

  const SetSymbolsSection({super.key, required this.setSymbols});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80, // Adjust height as needed
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: setSymbols.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(setSymbols[index]),
              backgroundColor: Colors.transparent, // Ensure transparent background to see full image
            ),
          );
        },
      ),
    );
  }
}

class CardsGridSection extends StatelessWidget {
  final List<Map<String, dynamic>> cards;

  const CardsGridSection({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 63 / 88, // Aspect ratio for standard card dimensions
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return Card(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 63 / 88, // Aspect ratio for standard card dimensions
                    child: card['image'] != null
                        ? Image.network(
                            card['image'],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(child: Text('Error loading image'));
                            },
                          )
                        : const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(card['name'] ?? 'Unknown Card', textAlign: TextAlign.center),
              ],
            ),
          );
        },
      ),
    );
  }
}
