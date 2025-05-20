import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.pinkAccent, size: 30),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.pinkAccent,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    'Welcome, Admin!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? 'No email found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            _buildDashboardCard(
              icon: Icons.report_problem,
              title: 'View Complaints',
              onTap: () => Navigator.pushNamed(context, '/admin/view_complaints'),
            ),

            _buildDashboardCard(
              icon: Icons.contact_page,
              title: 'Trusted Contacts Rules',
              onTap: () => Navigator.pushNamed(context, '/admin/trusted_contacts_rules'),
            ),

            _buildDashboardCard(
              icon: Icons.people,
              title: 'View Users',
              onTap: () => Navigator.pushNamed(context, '/admin/view_users'),
            ),

            _buildDashboardCard(
              icon: Icons.settings,
              title: 'Manage App Settings',
              onTap: () => Navigator.pushNamed(context, '/admin/manage_settings'),
            ),
          ],
        ),
      ),
    );
  }
}
