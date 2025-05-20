import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SOSSettingsScreen extends StatefulWidget {
  const SOSSettingsScreen({Key? key}) : super(key: key);

  @override
  State<SOSSettingsScreen> createState() => _SOSSettingsScreenState();
}

class _SOSSettingsScreenState extends State<SOSSettingsScreen> {
  final TextEditingController _sosMessageController = TextEditingController();
  final TextEditingController _emergencyNumberController = TextEditingController();
  bool _fakeCallEnabled = true;
  bool _isLoading = true;

  final _settingsRef = FirebaseFirestore.instance.collection('settings').doc('sos');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await _settingsRef.get();
    if (doc.exists) {
      final data = doc.data()!;
      _sosMessageController.text = data['message'] ?? '';
      _emergencyNumberController.text = data['emergency_number'] ?? '';
      _fakeCallEnabled = data['fake_call_enabled'] ?? true;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    final data = {
      'message': _sosMessageController.text.trim(),
      'emergency_number': _emergencyNumberController.text.trim(),
      'fake_call_enabled': _fakeCallEnabled,
    };
    await _settingsRef.set(data);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SOS settings updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Settings'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  TextFormField(
                    controller: _sosMessageController,
                    decoration: const InputDecoration(
                      labelText: 'Default SOS Message',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emergencyNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Contact Number',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _fakeCallEnabled,
                    onChanged: (value) {
                      setState(() => _fakeCallEnabled = value);
                    },
                    title: const Text('Enable Fake Call Feature'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text('Save Settings'),
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
