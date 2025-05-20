import 'package:flutter/material.dart';

class ManageSettingsScreen extends StatelessWidget {
  const ManageSettingsScreen({Key? key}) : super(key: key);

  Widget _buildSettingOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.pinkAccent),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  void _showAppVersionDialog(BuildContext context) {
    const currentVersion = '1.0.0';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('App Version Control'),
        content: Text('Current app version is $currentVersion.\n\nDo you want to check for updates?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('You are already on the latest version!')),
              );
            },
            child: const Text('Check'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage App Settings'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: ListView(
        children: [
          _buildSettingOption(
            icon: Icons.sos,
            title: 'SOS Settings',
            onTap: () => Navigator.pushNamed(context, '/admin/sos_settings'),
          ),
          _buildSettingOption(
            icon: Icons.update,
            title: 'App Version Control',
            onTap: () => _showAppVersionDialog(context),
          ),
        ],
      ),
    );
  }
}
