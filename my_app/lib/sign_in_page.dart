import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart'; // Ensure HomeScreen is correctly imported


class SignInPage extends StatefulWidget {
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
      // Navigate to Home or any other page
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
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
      // Optionally update the display name
      await userCredential.user?.updateDisplayName(nameController.text);
      // Navigate to Home or any other page
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
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
                    decoration: InputDecoration(labelText: 'Username or Email'),
                  ),
                  SizedBox(height: 16.0),
                  TextField(
                    controller: signInPasswordController,
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: signIn,
                    child: Text('Sign In'),
                  ),
                  TextButton(
                    onPressed: () {
                      // Handle forgot email or password functionality
                    },
                    child: Text('Forgot Email or Password?'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isSignIn = false;
                      });
                    },
                    child: Text('Create an Account'),
                  ),
                ],
              )
            else
              Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                  ),
                  SizedBox(height: 16.0),
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(labelText: 'Username'),
                  ),
                  SizedBox(height: 16.0),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                  SizedBox(height: 16.0),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  SizedBox(height: 16.0),
                  TextField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(labelText: 'Confirm Password'),
                    obscureText: true,
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: createAccount,
                    child: Text('Create Account'),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isSignIn = true;
                      });
                    },
                    child: Text('Already have an account? Sign In'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
