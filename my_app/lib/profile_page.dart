import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  bool _notificationsEnabled = false;

  ProfilePage({super.key});

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
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16.0),
            SwitchListTile(
              title: const Text('Enable Notifications'),
              value: _notificationsEnabled,
              onChanged: (bool value) {
                _notificationsEnabled = value;
              },
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // Handle logout functionality
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
