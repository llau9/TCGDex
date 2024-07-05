import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchResults = [];
  final Map<String, String> _cardImages = {};
  bool csvLoaded = false;

  @override
  void initState() {
    super.initState();
    checkCSVLoaded();
  }

  void checkCSVLoaded() async {
    const platform = MethodChannel('com.example/tcgdex');
    try {
      final bool result = await platform.invokeMethod('isCSVLoaded');
      setState(() {
        csvLoaded = result;
        print('CSV loaded status: $csvLoaded');
      });
    } on PlatformException catch (e) {
      print('Failed to check CSV load status: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check CSV load status: ${e.message}')));
    }
  }

  void _search() async {
    const platform = MethodChannel('com.example/tcgdex');
    String name = _searchController.text;

    if (!csvLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV file not loaded yet')));
      return;
    }

    try {
      final List<dynamic> results = await platform.invokeMethod('searchCards', {'name': name});
      setState(() {
        _searchResults = results.cast<String>();
      });

      for (String cardId in _searchResults) {
        _fetchCardImage(cardId);
      }
    } on PlatformException catch (e) {
      print('Failed to search cards: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to search cards: ${e.message}')));
    }
  }

  void _fetchCardImage(String cardId) async {
    const platform = MethodChannel('com.example/tcgdex');
    try {
      final Map<Object?, Object?> cardDetails =
          await platform.invokeMethod('fetchCardDetails', {'cardId': cardId});
      final String imageUrl = cardDetails['image'] as String? ?? '';
      setState(() {
        _cardImages[cardId] = imageUrl;
      });
      print('Fetched image URL for $cardId: $imageUrl');
    } on PlatformException catch (e) {
      print('Failed to fetch card image: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch card image: ${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _search,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Enter card name (e.g., Snorlax)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(child: Text('No results found'))
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 63 / 88, // Aspect ratio for standard card dimensions
                      ),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        String cardId = _searchResults[index];
                        String imageUrl = _cardImages[cardId] ?? '';

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Expanded(
                                  child: AspectRatio(
                                    aspectRatio: 63 / 88, // Aspect ratio for standard card dimensions
                                    child: imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Center(child: Text('Error loading image'));
                                            },
                                          )
                                        : const Center(child: CircularProgressIndicator()),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  cardId,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12.0),
                                ),
                              ],
                            ),
                          ),
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
