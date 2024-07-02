import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'home_screen.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void signIn() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: signInEmailOrUsernameController.text,
        password: signInPasswordController.text,
      );
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()));
    } catch (e) {
      print(e);
    }
  }

  void createAccount() async {
    if (passwordController.text != confirmPasswordController.text) {
      print('Passwords do not match');
      return;
    }

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      await userCredential.user?.updateDisplayName(nameController.text);

      // Create a new document for the user in the 'users' collection
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'name': nameController.text,
        'username': usernameController.text,
        'email': emailController.text,
        'portfolio': [],
        // Add other fields as needed
      });

      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()));
    } catch (e) {
      print(e);
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
