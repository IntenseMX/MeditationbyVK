import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Profile Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Your meditation profile',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}