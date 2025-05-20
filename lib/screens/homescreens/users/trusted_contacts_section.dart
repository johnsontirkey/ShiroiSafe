import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class TrustedContactsSection extends StatefulWidget {
  const TrustedContactsSection({Key? key}) : super(key: key);

  @override
  State<TrustedContactsSection> createState() => _TrustedContactsSectionState();
}

class _TrustedContactsSectionState extends State<TrustedContactsSection> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationController = TextEditingController();

  late PageController _pageController;
  Timer? _autoSlideTimer;
  int _currentPage = 0;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.6);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    _pageController.dispose();
    _autoSlideTimer?.cancel();
    super.dispose();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_totalPages == 0) return;
      _currentPage++;
      if (_currentPage >= _totalPages) {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _showAddContactDialog() async {
    _nameController.clear();
    _phoneController.clear();
    _relationController.clear();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Trusted Contact"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            TextField(controller: _relationController, decoration: const InputDecoration(labelText: 'Relation')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              final phone = _phoneController.text.trim();
              final relation = _relationController.text.trim();

              if (name.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Name and phone cannot be empty")),
                );
                return;
              }

              final phoneRegExp = RegExp(r'^\d{10}$');
              if (!phoneRegExp.hasMatch(phone)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Phone number must be exactly 10 digits.")),
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('trusted_contacts')
                  .add({
                'name': name,
                'phone': phone,
                'relation': relation,
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContact(String docId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('trusted_contacts')
        .doc(docId)
        .delete();
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch phone app")),
      );
    }
  }

  IconData _getRelationIcon(String relation) {
    final rel = relation.toLowerCase();
    if (rel.contains('father')) return Icons.male;
    if (rel.contains('mother')) return Icons.female;
    if (rel.contains('brother')) return Icons.man;
    if (rel.contains('sister')) return Icons.woman;
    if (rel.contains('friend')) return Icons.person;
    return Icons.people;
  }

  Widget _buildCompactCard(DocumentSnapshot contact) {
    String name = contact['name'];
    String phone = contact['phone'];
    String relation = contact['relation'] ?? "";

    return Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.redAccent.shade100,
            child: Icon(_getRelationIcon(relation), color: Colors.redAccent.shade400, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(relation, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call, size: 16, color: Colors.green),
            onPressed: () => _makePhoneCall(phone),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 16, color: Colors.red),
            onPressed: () => _deleteContact(contact.id),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                "Trusted Contacts",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showAddContactDialog,
                icon: const Icon(Icons.add_circle),
                label: const Text("Add Contact"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .collection('trusted_contacts')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              _autoSlideTimer?.cancel(); // stop timer if no data
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text("No trusted contacts added yet."),
              );
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _totalPages = snapshot.data!.docs.length;
              _startAutoSlide();
            });

            return SizedBox(
              height: 80,
              child: PageView.builder(
                controller: _pageController,
                itemCount: snapshot.data!.docs.length,
                onPageChanged: (index) => _currentPage = index,
                itemBuilder: (context, index) {
                  var contact = snapshot.data!.docs[index];
                  return _buildCompactCard(contact);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
