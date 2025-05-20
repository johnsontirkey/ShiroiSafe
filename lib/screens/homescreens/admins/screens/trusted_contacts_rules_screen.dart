import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrustedContactsRulesScreen extends StatefulWidget {
  const TrustedContactsRulesScreen({Key? key}) : super(key: key);

  @override
  State<TrustedContactsRulesScreen> createState() => _TrustedContactsRulesScreenState();
}

class _TrustedContactsRulesScreenState extends State<TrustedContactsRulesScreen> {
  final TextEditingController _maxContactsController = TextEditingController();
  bool _onlyVerified = false;
  bool _isLoading = true;

  final _settingsRef = FirebaseFirestore.instance.collection('settings').doc('trusted_contacts_rules');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await _settingsRef.get();
    if (doc.exists) {
      final data = doc.data()!;
      _maxContactsController.text = (data['max_contacts'] ?? 5).toString();
      _onlyVerified = data['only_verified'] ?? false;
    } else {
      // Defaults
      _maxContactsController.text = '5';
      _onlyVerified = false;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    int maxContacts = int.tryParse(_maxContactsController.text) ?? 5;
    if (maxContacts < 1) maxContacts = 1;

    await _settingsRef.set({
      'max_contacts': maxContacts,
      'only_verified': _onlyVerified,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trusted Contacts rules updated')),
    );
  }

  @override
  void dispose() {
    _maxContactsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted Contacts Rules'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  TextFormField(
                    controller: _maxContactsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max Trusted Contacts per User',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('SOS Alerts Only to Verified Contacts'),
                    value: _onlyVerified,
                    onChanged: (val) => setState(() => _onlyVerified = val),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text('Save Rules'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
