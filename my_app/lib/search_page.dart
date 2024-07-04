import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _setController = TextEditingController();
  final TextEditingController _seriesController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();

  List<String> _searchResults = [];

  void _search() async {
    const platform = MethodChannel('com.example/tcgdex');
    try {
      final List<dynamic> results = await platform.invokeMethod('searchCards', {
        'name': _nameController.text,
        'set': _setController.text,
        'series': _seriesController.text,
        'artist': _artistController.text,
      });
      setState(() {
        _searchResults = results.cast<String>();
      });
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to search cards: ${e.message}')));
    }
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Card Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _setController,
              decoration: InputDecoration(
                labelText: 'Set',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _seriesController,
              decoration: InputDecoration(
                labelText: 'Series',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _artistController,
              decoration: InputDecoration(
                labelText: 'Artist',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _search,
              child: const Text('Search'),
            ),
            const SizedBox(height: 16),
            ..._searchResults.map((id) => ListTile(
              title: Text(id),
              onTap: () => _fetchCardDetails(id),
            )).toList(),
          ],
        ),
      ),
    );
  }
}
