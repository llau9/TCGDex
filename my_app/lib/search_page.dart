import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'card_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchResults = [];
  List<String> _suggestions = []; // List to hold suggestions for autofill
  final Map<String, String> _cardImages = {};
  bool csvLoaded = false;
  bool _filtersVisible = true;

  List<String> _activeFilters = []; // Stores the active filters as strings

  // Filter data based on CSV headers
  final Map<String, List<String>> filterOptions = {
    'Name': ['Pikachu', 'Charizard'],
    'Set': ['Evolving Skies', 'Fusion Strike'],
    'Series': ['Sword & Shield', 'Sun & Moon'],
    'Publisher': ['Pokemon', 'Wizards of the Coast'],
    'Generation': ['1', '2', '3'],
    'Artist': ['Ken Sugimori', 'Mitsuhiro Arita'],
    'Type': ['Fire', 'Water', 'Grass'],
    'Rarity': ['Common', 'Uncommon', 'Rare'],
  };

  static const platform = MethodChannel('com.example/tcgdex');

  @override
  void initState() {
    super.initState();
    checkCSVLoaded();
    _searchController.addListener(_updateSuggestions); // Add listener for autofill
  }

  void checkCSVLoaded() async {
    try {
      final bool result = await platform.invokeMethod('isCSVLoaded');
      setState(() {
        csvLoaded = result;
      });
    } on PlatformException catch (e) {
      print('Failed to check CSV load status: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check CSV load status: ${e.message}')));
    }
  }

  void _updateSuggestions() async {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    final parts = query.split(':');
    if (parts.length < 2) return;

    final category = parts[0].trim();
    final subQuery = parts[1].trim();

    if (filterOptions.containsKey(category)) {
      try {
        final List<dynamic> results = await platform.invokeMethod('getSuggestions', {'category': category, 'query': subQuery});
        setState(() {
          _suggestions = List<String>.from(results);
        });
      } on PlatformException catch (e) {
        print('Failed to get suggestions: ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to get suggestions: ${e.message}')));
      }
    }
  }

  void _search() async {
    if (!csvLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV file not loaded yet')));
      return;
    }

    try {
      final List<dynamic> results = await platform.invokeMethod('searchCards', {'filters': _activeFilters.join(', ')});
      setState(() {
        _searchResults = results.cast<String>();
        _filtersVisible = false;
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
    try {
      final Map<Object?, Object?> cardDetails = await platform.invokeMethod('fetchCardDetails', {'cardId': cardId});
      final String imageUrl = cardDetails['image'] as String? ?? '';
      if (imageUrl.isNotEmpty) {
        setState(() {
          _cardImages[cardId] = imageUrl;
        });
      }
    } on PlatformException catch (e) {
      print('Failed to fetch card image: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch card image: ${e.message}')));
    }
  }

  void _navigateToCardDetails(String cardId) async {
    try {
      final Map<Object?, Object?> cardDetailsMap = await platform.invokeMethod('fetchCardDetails', {'cardId': cardId});
      final Map<String, String> cardDetails = cardDetailsMap.map((key, value) => MapEntry(key.toString(), value.toString()));
      final String imageUrl = cardDetails['image'] ?? '';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CardDetailPage(
            cardId: cardId,
            imageUrl: imageUrl,
            cardDetails: cardDetails,
          ),
        ),
      );
    } on PlatformException catch (e) {
      print('Failed to fetch card details: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch card details: ${e.message}')));
    }
  }

  void _addFilterToSearchBar(String filter) {
    setState(() {
      _searchController.text = _searchController.text.isEmpty
          ? filter
          : '${_searchController.text}, $filter';
    });
  }

  void _addActiveFilter(String filter) {
    setState(() {
      _activeFilters.add(filter);
    });
  }

  void _removeActiveFilter(String filter) {
    setState(() {
      _activeFilters.remove(filter);
    });
  }

  void _onSubmitted(String value) {
    if (value.isNotEmpty) {
      _addActiveFilter(value);
      _searchController.clear();
      setState(() {
        _suggestions = []; // Clear suggestions after submitting
      });
    }
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: _activeFilters.map((filter) {
        return Chip(
          label: Text(filter),
          onDeleted: () => _removeActiveFilter(filter),
        );
      }).toList(),
    );
  }

  Widget _buildSearchField() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  ..._activeFilters.map((filter) {
                    return Chip(
                      label: Text(filter),
                      onDeleted: () => _removeActiveFilter(filter),
                    );
                  }).toList(),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Add filter',
                      ),
                      onSubmitted: _onSubmitted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _search,
            ),
          ],
        ),
        _suggestions.isEmpty
            ? Container()
            : Container(
                alignment: Alignment.centerLeft,
                child: Column(
                  children: _suggestions.map((suggestion) {
                    return GestureDetector(
                      onTap: () {
                        final currentText = _searchController.text;
                        final parts = currentText.split(':');
                        if (parts.length > 1) {
                          final category = parts[0].trim();
                          _searchController.text = '$category: $suggestion';
                        }
                        _updateSuggestions(); // Update suggestions after selection
                      },
                      child: Chip(
                        label: Text(suggestion),
                      ),
                    );
                  }).toList(),
                ),
              ),
      ],
    );
  }

  Widget _buildFilterDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: filterOptions.entries.map((entry) {
        String filterCategory = entry.key;
        String sampleValues = entry.value.join(', ');
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _addFilterToSearchBar('$filterCategory: '),
                child: Text(
                  '$filterCategory: ',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
              Expanded(
                child: Text(
                  sampleValues,
                  style: const TextStyle(color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey),
              ),
              child: _buildSearchField(),
            ),
            const SizedBox(height: 16),
            _filtersVisible
                ? Expanded(
                    child: ListView(
                      children: [
                        const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                        _buildFilterDisplay(),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            // Implement show all filters logic
                            print('Show all filters');
                          },
                          child: const Text(
                            'Show all filters',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  )
                : Expanded(
                    child: _searchResults.isEmpty
                        ? const Center(child: Text('No results found'))
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8.0,
                              mainAxisSpacing: 8.0,
                              childAspectRatio: 63 / 88, // Aspect ratio for standard card dimensions
                            ),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              String cardId = _searchResults[index];
                              String imageUrl = _cardImages[cardId] ?? '';

                              return GestureDetector(
                                onTap: () => _navigateToCardDetails(cardId),
                                child: Card(
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
                                          style: const TextStyle(fontSize: 12.0),
                                        ),
                                      ],
                                    ),
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
