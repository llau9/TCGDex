import 'package:flutter/material.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_cart,
              size: 100,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Add your logic to browse items or go back to the marketplace
              },
              child: const Text('Browse Items'),
            ),
          ],
        ),
      ),
    );
  }
}