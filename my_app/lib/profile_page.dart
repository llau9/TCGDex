import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_in_page.dart'; // Ensure this is correctly imported

class ProfilePage extends StatelessWidget {
  ProfilePage({Key? key}) : super(key: key);

  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.person),
              title: Text(user?.displayName ?? 'No username'),
              subtitle: Text('Username'),
            ),
            const SizedBox(height: 16.0),
            ListTile(
              leading: Icon(Icons.email),
              title: Text(user?.email ?? 'No email'),
              subtitle: Text('Email'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => SignInPage()),
                );
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}