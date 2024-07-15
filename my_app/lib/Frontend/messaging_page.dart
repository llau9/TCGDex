import 'package:flutter/material.dart';

class MessagingPage extends StatelessWidget {
  const MessagingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messaging'),
      ),
      body: Row(
        children: [
          // Contacts List
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[850],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Contacts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 20, // Number of contacts
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            'Contact ${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            // Handle contact selection
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Messaging Section
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey[900],
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: 50, // Number of messages
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            'Message from User ${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'This is message ${index + 1}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        );
                      },
                    ),
                  ),
                  // Message Input
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    color: Colors.grey[800],
                    child: Row(
                      children: [
                        const Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Type a message',
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () {
                            // Handle message sending
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
