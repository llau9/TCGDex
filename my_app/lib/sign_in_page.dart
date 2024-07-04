import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart'; // Ensure HomeScreen is correctly imported
import 'package:cloud_firestore/cloud_firestore.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key); // Ensure constructor is const

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool isSignIn = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController signInEmailOrUsernameController = TextEditingController();
  final TextEditingController signInPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void signIn() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: signInEmailOrUsernameController.text,
        password: signInPasswordController.text,
      );

      if (userCredential.user != null) {
        // User is successfully authenticated, navigate to HomeScreen
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to sign in: $e'),
      ));
    }
  }

  void createAccount() async {
  if (passwordController.text != confirmPasswordController.text) {
    print('Passwords do not match');
    return;
  }

  try {
    print('Attempting to create user...');
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: emailController.text,
      password: passwordController.text,
    );
    print('User created: ${userCredential.user?.uid}');

    // Save user data to Firestore
    await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
      'name': nameController.text,
      'username': usernameController.text,
      'email': emailController.text,
    });
    print('User data saved to Firestore');

    // Create portfolios subcollection for the user
    CollectionReference portfolios = FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).collection('portfolio');

    // Add Default Portfolio
    await portfolios.add({
      'portfolioName': 'Default Portfolio',
      // Add more fields as needed
    });
    print('Default Portfolio created');

    // Add Wishlist Portfolio
    await portfolios.add({
      'portfolioName': 'Wishlist',
      // Add more fields as needed
    });
    print('Wishlist Portfolio created');

    // Optionally update the display name
    await userCredential.user?.updateDisplayName(nameController.text);

    // Navigate to HomeScreen
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
  } catch (e) {
    print('Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Failed to create account: $e'),
    ));
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isSignIn ? 'Sign In' : 'Create Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            if (isSignIn)
              Column(
                children: [
                  TextField(
                    controller: signInEmailOrUsernameController,
                    decoration: const InputDecoration(labelText: 'Username or Email'),
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: signInPasswordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: signIn,
                    child: const Text('Sign In'),
                  ),
                  TextButton(
                    onPressed: () {
                      // Handle forgot email or password functionality
                    },
                    child: const Text('Forgot Email or Password?'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isSignIn = false;
                      });
                    },
                    child: const Text('Create an Account'),
                  ),
                ],
              )
            else
              Column(
                children: [
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
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: confirmPasswordController,
                    decoration: const InputDecoration(labelText: 'Confirm Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: createAccount,
                    child: const Text('Create Account'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isSignIn = true;
                      });
                    },
                    child: const Text('Already have an account? Sign In'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}