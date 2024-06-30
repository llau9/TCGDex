import 'package:flutter/material.dart';

class PortfolioPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Portfolio'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileSection(),
            FilterAndSymbolsSection(),
            CardsGridSection(),
          ],
        ),
      ),
    );
  }
}

class ProfileSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage('assets/profile.jpg'),
          ),
          SizedBox(width: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Jayle Proffiec', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
              Text('Level 12', style: TextStyle(color: Colors.grey[600])),
              Text('360/500 XP', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}

class FilterAndSymbolsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () {},
            icon: Icon(Icons.filter_list),
            label: Text('Filter'),
          ),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber),
              SizedBox(width: 4.0),
              Icon(Icons.access_time, color: Colors.grey),
              SizedBox(width: 4.0),
              Icon(Icons.favorite, color: Colors.red),
            ],
          ),
        ],
      ),
    );
  }
}

class CardsGridSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          return Card(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 50, color: Colors.grey),
                SizedBox(height: 8.0),
                Text('Card ${index + 1}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
