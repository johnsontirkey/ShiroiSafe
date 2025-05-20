import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewUsersScreen extends StatelessWidget {
  const ViewUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data?.docs ?? [];

          if (users.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;

              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(userData['name'] ?? 'Unnamed'),
                subtitle: Text(userData['email'] ?? 'No email'),
                onTap: () {
                  // Navigate to details screen and pass the user data
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserDetailsScreen(
                        userData: userData,
                        userId: userDoc.id,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class UserDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String userId;

  const UserDetailsScreen({Key? key, required this.userData, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // You can customize this screen to show whatever user details you want
    return Scaffold(
      appBar: AppBar(
        title: Text(userData['name'] ?? 'User Details'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              title: const Text('User ID'),
              subtitle: Text(userId),
            ),
            ListTile(
              title: const Text('Name'),
              subtitle: Text(userData['name'] ?? 'N/A'),
            ),
            ListTile(
              title: const Text('Email'),
              subtitle: Text(userData['email'] ?? 'N/A'),
            ),
            ListTile(
              title: const Text('Phone'),
              subtitle: Text(userData['phone'] ?? 'N/A'),
            ),
            ListTile(
              title: const Text('Role'),
              subtitle: Text(userData['role'] ?? 'N/A'),
            ),
            // Add more fields here as per your user document structure
          ],
        ),
      ),
    );
  }
}
