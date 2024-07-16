import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'home_screen.dart';
// Ensure SignInPage is correctly imported

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define a custom pastel red color
    const pastelRed = Color(0xFFFF6961);

    return MaterialApp(
      title: 'Modern UI App',
      theme: ThemeData(
        primarySwatch: Colors.red,
        primaryColor: pastelRed,
        appBarTheme: const AppBarTheme(
          color: pastelRed,
          iconTheme: IconThemeData(color: Colors.white),
          actionsIconTheme: IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: pastelRed,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const HomeScreen(), // Set HomeScreen as the default screen
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Access environment variables
    String apiKey = dotenv.env['API_KEY'] ?? 'default_api_key';
    String baseUrl = dotenv.env['BASE_URL'] ?? 'https://default.url.com';

    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter .env Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('API Key: $apiKey'),
            Text('Base URL: $baseUrl'),
          ],
        ),
      ),
    );
  }
}