import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filters = [];
  List<String> _searchResults = [];

  void _search() async {
    const platform = MethodChannel('com.example/tcgdex');
    Map<String, String> criteria = _parseFilters(_filters);
    print("Search criteria: $criteria"); // Debugging

    try {
      final List<dynamic> results = await platform.invokeMethod('searchCards', criteria);
      print("Search results: $results"); // Debugging
      setState(() {
        _searchResults = results.cast<String>();
      });
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to search cards: ${e.message}')));
    }
  }

  Map<String, String> _parseFilters(List<String> filters) {
    Map<String, String> criteria = {};
    for (String filter in filters) {
      List<String> parts = filter.split(':');
      if (parts.length == 2) {
        String key = parts[0].trim().toLowerCase();
        String value = parts[1].trim();
        criteria[key] = value;
      }
    }
    return criteria;
  }

  void _addFilter(String filter) {
    setState(() {
      _filters.add(filter);
    });
  }

  void _removeFilter(int index) {
    setState(() {
      _filters.removeAt(index);
    });
  }

  void _fetchCardDetails(String cardId) async {
    const platform = MethodChannel('com.example/tcgdex');
    try {
      final String cardName = await platform.invokeMethod('fetchCardDetails', {'cardId': cardId});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Card Name: $cardName')));
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to fetch card details: ${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Cards'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
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
                hintText: 'Enter filter (e.g., name: Pikachu)',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      _addFilter(_searchController.text);
                      _searchController.clear();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              children: _filters.asMap().entries.map((entry) {
                int index = entry.key;
                String filter = entry.value;
                return Chip(
                  label: Text(filter),
                  onDeleted: () => _removeFilter(index),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: _searchResults.map((id) {
                  return ListTile(
                    title: Text(id),
                    onTap: () => _fetchCardDetails(id),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
