import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyServicesScreen extends StatelessWidget {
  const EmergencyServicesScreen({Key? key}) : super(key: key);

  void _navigateToAddService(BuildContext context) {
    Navigator.pushNamed(context, '/admin/add_edit_service');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Services'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('emergency_services').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading data'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final services = snapshot.data!.docs;

          if (services.isEmpty) {
            return const Center(child: Text('No emergency services found.'));
          }

          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final data = services[index].data() as Map<String, dynamic>;
              final docId = services[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(data['name'] ?? 'Unnamed'),
                  subtitle: Text('${data['type']} • ${data['contact']}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.pushNamed(context, '/admin/add_edit_service', arguments: {
                          'docId': docId,
                          'data': data,
                        });
                      } else if (value == 'delete') {
                        FirebaseFirestore.instance.collection('emergency_services').doc(docId).delete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddService(context),
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.add),
        tooltip: 'Add Emergency Service',
      ),
    );
  }
}
