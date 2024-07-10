import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class AuthService {
  final String clientId = 'YOUR_EBAY_APP_ID';
  final String clientSecret = 'YOUR_EBAY_CLIENT_SECRET';
  final String redirectUri = 'YOUR_REDIRECT_URI';
  final String authorizationEndpoint = 'https://auth.ebay.com/oauth2/authorize';
  final String tokenEndpoint = 'https://api.ebay.com/identity/v1/oauth2/token';
  final storage = FlutterSecureStorage();

  Future<String> getAccessToken(BuildContext context) async {
    final String? savedToken = await storage.read(key: 'access_token');
    if (savedToken != null) {
      return savedToken;
    }

    final String authUrl = '$authorizationEndpoint?client_id=$clientId&redirect_uri=$redirectUri&response_type=code&scope=https://api.ebay.com/oauth/api_scope';

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewPage(authUrl: authUrl),
      ),
    );

    if (result != null && result.contains('code=')) {
      final code = result.split('code=')[1];
      return _exchangeCodeForToken(code);
    }

    throw Exception('Authorization failed');
  }

  Future<String> _exchangeCodeForToken(String code) async {
    final String credentials = '$clientId:$clientSecret';
    final String encodedCredentials = base64Encode(utf8.encode(credentials));

    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {
        'Authorization': 'Basic $encodedCredentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: 'grant_type=authorization_code&code=$code&redirect_uri=$redirectUri',
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final String accessToken = data['access_token'];
      await storage.write(key: 'access_token', value: accessToken);
      return accessToken;
    } else {
      throw Exception('Failed to exchange code for token');
    }
  }

  Future<void> clearToken() async {
    await storage.delete(key: 'access_token');
  }
}

class WebViewPage extends StatelessWidget {
  final String authUrl;
  final flutterWebviewPlugin = FlutterWebviewPlugin();

  WebViewPage({required this.authUrl});

  @override
  Widget build(BuildContext context) {
    flutterWebviewPlugin.onUrlChanged.listen((String url) {
      if (url.startsWith('YOUR_REDIRECT_URI')) {
        flutterWebviewPlugin.stopLoading();
        Navigator.pop(context, url);
      }
    });

    return WebviewScaffold(
      url: authUrl,
      appBar: AppBar(title: Text('eBay Login')),
    );
  }
}
