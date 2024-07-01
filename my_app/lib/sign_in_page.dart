import 'package:flutter/material.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

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
                    onPressed: () {
                      // Handle sign in functionality
                    },
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
                    onPressed: () {
                      // Handle create account functionality
                    },
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
