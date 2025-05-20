import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isLoading = true;

  final _settingsRef = FirebaseFirestore.instance.collection('settings').doc('notifications');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await _settingsRef.get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _notificationsEnabled = data['enabled'] ?? true;
        _isLoading = false;
      });
    } else {
      // Create default
      await _settingsRef.set({'enabled': true});
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(bool value) async {
    setState(() => _notificationsEnabled = value);
    await _settingsRef.update({'enabled': value});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _notificationsEnabled,
                    onChanged: _updateSetting,
                    title: const Text('Enable Notifications'),
                    subtitle: const Text('Globally control push notifications for users'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'More settings coming soon...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }
}
