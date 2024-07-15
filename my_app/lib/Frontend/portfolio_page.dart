import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'card_detail_page.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  _PortfolioPageState createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  String userName = "Anonymous";
  String selectedSeriesName = "Select Series";
  List<String> allSetSymbols = [];
  List<String> setSymbols = [];
  List<Map<String, dynamic>> portfolioCards = [];
  List<Map<String, dynamic>> setCards = [];
  Set<String> ownedCardIds = <String>{};
  List<Map<String, String>> seriesList = [];

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchSeries();
    _fetchAllSetSymbols();
    _fetchPortfolioCards();
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      userName = user?.displayName ?? "Anonymous";
    });
  }

  Future<void> _fetchSeries() async {
    const platform = MethodChannel('com.example/tcgdex');
    try {
      final List<dynamic> result = await platform.invokeMethod('fetchSeries');
      setState(() {
        seriesList = result.map((dynamic series) => Map<String, String>.from(series)).toList();
        seriesList.insert(0, {'id': 'recently_added', 'name': 'Recently Added'});
      });
    } on PlatformException catch (e) {
      print("Failed to fetch series: '${e.message}'.");
    }
  }

  Future<void> _fetchAllSetSymbols() async {
    const platform = MethodChannel('com.example/tcgdex');
    try {
      final List<dynamic> result = await platform.invokeMethod('fetchAllSetSymbols');
      setState(() {
        allSetSymbols = result.cast<String>();
        setSymbols = allSetSymbols; // Display all sets by default
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
        ownedCardIds.add(cardId);  // Add cardId to the set of owned cards
        await _fetchCardDetails(cardId);
      }
    }
  }

  Future<void> _fetchCardDetails(String cardId) async {
    const platform = MethodChannel('com.example/tcgdex');
    try {
      final Map<dynamic, dynamic> result = await platform.invokeMethod('fetchCardDetails', {'cardId': cardId});
      final Map<String, dynamic> cardDetails = Map<String, dynamic>.from(result);
      setState(() {
        portfolioCards.add(cardDetails);
      });
    } on PlatformException catch (e) {
      print("Failed to fetch card details: '${e.message}'.");
    }
  }

  Future<void> _fetchCardsBySetId(String setId) async {
    if (setId == 'recently_added') {
      setState(() {
        setSymbols = allSetSymbols;
        setCards = [];
      });
    } else {
      const platform = MethodChannel('com.example/tcgdex');
      try {
        final List<dynamic> result = await platform.invokeMethod('fetchCardsBySetId', {'setId': setId});
        final List<Map<String, dynamic>> cards = result.map((dynamic item) => Map<String, dynamic>.from(item)).toList();
        setState(() {
          setCards = cards;
        });
      } on PlatformException catch (e) {
        print("Failed to fetch cards by set ID: '${e.message}'.");
      }
    }
  }

  void _onSetSymbolClicked(String setId) {
    _fetchCardsBySetId(setId);
  }

  void _onCardClicked(Map<String, dynamic> card) {
    final Map<String, String> cardDetails = card.map((key, value) => MapEntry(key.toString(), value.toString()));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardDetailPage(
          cardId: card['id'],
          imageUrl: card['image'],
          cardDetails: cardDetails,
        ),
      ),
    );
  }

  Future<void> _fetchSetSymbolsBySeries(String seriesId) async {
    if (seriesId == 'recently_added') {
      setState(() {
        setSymbols = allSetSymbols;
        setCards = [];
      });
    } else {
      const platform = MethodChannel('com.example/tcgdex');
      try {
        final List<dynamic> result = await platform.invokeMethod('fetchSerie', {'seriesId': seriesId});
        final List<String> setSymbols = result.map((dynamic set) => "${set['symbol']}.png").toList();
        setState(() {
          this.setSymbols = setSymbols;
          setCards = [];
        });
      } on PlatformException catch (e) {
        print("Failed to fetch sets by series ID: '${e.message}'.");
      }
    }
  }

  void _onSeriesSelected(String seriesId, String seriesName) {
    setState(() {
      selectedSeriesName = seriesName;
    });
    _fetchSetSymbolsBySeries(seriesId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ProfileSection(userName: userName),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: SeriesDropdown(
                    selectedSeriesName: selectedSeriesName,
                    seriesList: seriesList,
                    onSeriesSelected: _onSeriesSelected,
                  ),
                ),
              ],
            ),
            SetSymbolsSection(
              setSymbols: setSymbols,
              onSetSymbolClicked: _onSetSymbolClicked,
              showRecentlyAdded: true,
            ),
            CardsGridSection(
              cards: setCards.isNotEmpty ? setCards : portfolioCards,
              onCardClicked: _onCardClicked,
              ownedCardIds: ownedCardIds,
            ),
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
      padding: const EdgeInsets.all(8.0),  // Reduced padding
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,  // Reduced radius
            backgroundImage: AssetImage('assets/profile.jpg'),
          ),
          const SizedBox(width: 8.0),  // Reduced width
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),  // Reduced font size
                Text('Level 12', style: TextStyle(color: Colors.grey[600])),
                Text('360/500 XP', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SeriesDropdown extends StatelessWidget {
  final String selectedSeriesName;
  final List<Map<String, String>> seriesList;
  final Function(String, String) onSeriesSelected;

  const SeriesDropdown({
    super.key,
    required this.selectedSeriesName,
    required this.seriesList,
    required this.onSeriesSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      hint: Text(selectedSeriesName),
      items: seriesList.map((series) {
        return DropdownMenuItem<String>(
          value: series['id'],
          child: Text(series['name']!),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          final selectedSeries = seriesList.firstWhere((series) => series['id'] == newValue);
          onSeriesSelected(newValue, selectedSeries['name']!);
        }
      },
    );
  }
}

class SetSymbolsSection extends StatelessWidget {
  final List<String> setSymbols;
  final Function(String) onSetSymbolClicked;
  final bool showRecentlyAdded;

  const SetSymbolsSection({
    super.key,
    required this.setSymbols,
    required this.onSetSymbolClicked,
    this.showRecentlyAdded = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80, // Adjust height as needed
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: setSymbols.length + (showRecentlyAdded ? 1 : 0),
        itemBuilder: (context, index) {
          if (showRecentlyAdded && index == 0) {
            return GestureDetector(
              onTap: () => onSetSymbolClicked('recently_added'),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.new_releases, color: Colors.white),
                ),
              ),
            );
          } else {
            final symbolIndex = showRecentlyAdded ? index - 1 : index;
            // Extract the set ID from the URL
            final uri = Uri.parse(setSymbols[symbolIndex]);
            final setId = uri.pathSegments.length >= 3 ? uri.pathSegments[2] : 'unknown';
            return GestureDetector(
              onTap: () => onSetSymbolClicked(setId),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(setSymbols[symbolIndex]),
                  backgroundColor: Colors.transparent, // Ensure transparent background to see full image
                  onBackgroundImageError: (exception, stackTrace) {
                    print("Error loading image for $setId");
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2.0), // Black outline
                    ),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class CardsGridSection extends StatelessWidget {
  final List<Map<String, dynamic>> cards;
  final Function(Map<String, dynamic>) onCardClicked;
  final Set<String> ownedCardIds;

  const CardsGridSection({super.key, required this.cards, required this.onCardClicked, required this.ownedCardIds});

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
          final bool isOwned = ownedCardIds.contains(card['id']);

          return GestureDetector(
            onTap: () => onCardClicked(card),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(
                  color: isOwned ? Colors.green : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 63 / 88, // Aspect ratio for standard card dimensions
                        child: Stack(
                          children: [
                            card['image'] != null
                                ? Image.network(
                                    card['image'],
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(child: Text('Error loading image'));
                                    },
                                  )
                                : const Icon(Icons.image, size: 50, color: Colors.grey),
                            Positioned(
                              top: 8.0,
                              right: 8.0,
                              child: Icon(
                                isOwned ? Icons.check_circle : Icons.check_circle_outline,
                                color: isOwned ? Colors.green : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      card['name'] ?? 'Unknown Card',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12.0),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
