import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class OnlineComplaintPage extends StatefulWidget {
  const OnlineComplaintPage({Key? key}) : super(key: key);

  @override
  State<OnlineComplaintPage> createState() => _OnlineComplaintPageState();
}

class _OnlineComplaintPageState extends State<OnlineComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  File? _complaintImage;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Harassment',
    'Safety',
    'Theft',
    'Other',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _complaintImage = File(pickedFile.path));
    }
  }

  void _removeImage() {
    setState(() => _complaintImage = null);
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      String? imageUrl;

      if (_complaintImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('complaints')
            .child(user.uid)
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = await storageRef.putFile(_complaintImage!);
        imageUrl = await uploadTask.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('complaints').add({
        'userId': user.uid,
        'subject': _subjectController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory ?? 'Other',
        'imageUrl': imageUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'Pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint submitted successfully')),
      );

      _formKey.currentState?.reset();
      setState(() {
        _complaintImage = null;
        _selectedCategory = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit complaint: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);

    // Define colors
    final primaryColor = Colors.pink;
    final accentColor = Colors.redAccent.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Complaint'),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Subject
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(borderRadius: borderRadius),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: BorderSide(color: accentColor, width: 2),
                  ),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Please enter subject' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Select Category'),
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: borderRadius),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: BorderSide(color: accentColor, width: 2),
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please select a category' : null,
              ),
              const SizedBox(height: 18),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: borderRadius),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: BorderSide(color: accentColor, width: 2),
                  ),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Please enter description' : null,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 20),

              // Image Picker & Preview
              _complaintImage == null
                  ? OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.photo_camera_outlined, color: primaryColor),
                      label: Text(
                        'Add an image (optional)',
                        style: TextStyle(color: primaryColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: borderRadius),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    )
                  : Stack(
                      children: [
                        ClipRRect(
                          borderRadius: borderRadius,
                          child: Image.file(
                            _complaintImage!,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 20, color: Colors.white),
                              onPressed: _removeImage,
                            ),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 28),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComplaint,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: borderRadius),
                  elevation: 4,
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Text(
                        'Submit Complaint',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
