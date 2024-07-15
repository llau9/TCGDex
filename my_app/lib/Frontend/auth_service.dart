import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final String clientId = 'LucasLau-TCGProje-SBX-f941052cf-0995845e';
  final String clientSecret = 'SBX-941052cf3b5a-42c9-4cca-9416-74a1';
  final String tokenEndpoint = 'https://api.sandbox.ebay.com/identity/v1/oauth2/token';
  final storage = const FlutterSecureStorage();

  Future<String> getAccessToken() async {
    final String? savedToken = await storage.read(key: 'access_token');
    if (savedToken != null) {
      print('Using saved access token: $savedToken');
      return savedToken;
    }

    final String credentials = '$clientId:$clientSecret';
    final String encodedCredentials = base64Encode(utf8.encode(credentials));

    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {
        'Authorization': 'Basic $encodedCredentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=client_credentials&scope=https://api.ebay.com/oauth/api_scope',
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final String accessToken = data['access_token'];
      print('Obtained new access token: $accessToken');
      await storage.write(key: 'access_token', value: accessToken);
      return accessToken;
    } else {
      print('Failed to obtain access token: ${response.body}');
      throw Exception('Failed to obtain access token');
    }
  }

  Future<void> clearToken() async {
    await storage.delete(key: 'access_token');
  }
}

class MarketService {
  final AuthService authService = AuthService();

  Future<List<Map<String, dynamic>>> fetchEbayListings(String query) async {
    final String accessToken = await authService.getAccessToken();

    final response = await http.get(
      Uri.parse('https://api.sandbox.ebay.com/buy/browse/v1/item_summary/search?q=$query&limit=10'),
      headers: {
        'Authorization': accessToken,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['itemSummaries'] ?? []);
    } else {
      throw Exception('Failed to fetch eBay listings: ${response.body}');
    }
  }
}

void main() async {
  final authService = AuthService();
  try {
    final token = await authService.getAccessToken();
    print('OAuth Token: $token');
  } catch (e) {
    print('Error: $e');
  }
}
