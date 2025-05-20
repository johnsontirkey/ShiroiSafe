import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEditServiceScreen extends StatefulWidget {
  const AddEditServiceScreen({Key? key}) : super(key: key);

  @override
  State<AddEditServiceScreen> createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends State<AddEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();

  String _selectedType = 'Police';
  bool _isEdit = false;
  String? _docId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && args['data'] != null) {
      _isEdit = true;
      _docId = args['docId'];
      final data = args['data'] as Map<String, dynamic>;

      _nameController.text = data['name'] ?? '';
      _contactController.text = data['contact'] ?? '';
      _selectedType = data['type'] ?? 'Police';
      _latController.text = data['location']?['lat'].toString() ?? '';
      _lngController.text = data['location']?['lng'].toString() ?? '';
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) return;

    final data = {
      'name': _nameController.text.trim(),
      'contact': _contactController.text.trim(),
      'type': _selectedType,
      'location': {
        'lat': double.tryParse(_latController.text.trim()) ?? 0,
        'lng': double.tryParse(_lngController.text.trim()) ?? 0,
      },
    };

    final servicesRef = FirebaseFirestore.instance.collection('emergency_services');

    if (_isEdit && _docId != null) {
      await servicesRef.doc(_docId).update(data);
    } else {
      await servicesRef.add(data);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Service' : 'Add Service'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: 'Police', child: Text('Police')),
                  DropdownMenuItem(value: 'Hospital', child: Text('Hospital')),
                  DropdownMenuItem(value: 'Pink Booth', child: Text('Pink Booth')),
                ],
                onChanged: (val) => setState(() => _selectedType = val!),
                decoration: const InputDecoration(labelText: 'Service Type'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Service Name'),
                validator: (val) => val == null || val.isEmpty ? 'Please enter name' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Contact Number'),
                validator: (val) => val == null || val.isEmpty ? 'Please enter contact' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _latController,
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _lngController,
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(_isEdit ? 'Update Service' : 'Add Service'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
