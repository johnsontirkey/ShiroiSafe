import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final Map<String, dynamic> complaintData;

  const ComplaintDetailScreen({Key? key, required this.complaintData}) : super(key: key);

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    return DateFormat.yMMMd().add_jm().format(timestamp.toDate());
  }

  Future<Map<String, dynamic>?> _fetchUserLocation(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('locations').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('latitude') && data.containsKey('longitude')) {
          return data;
        }
      }
    } catch (e) {
      debugPrint("Error fetching location for user $userId: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final userId = complaintData['userId'] ?? '';
    final complaintId = complaintData['id'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserLocation(userId),
        builder: (context, locationSnapshot) {
          final location = locationSnapshot.data;
          LatLng? userLatLng;
          if (location != null && location.containsKey('latitude') && location.containsKey('longitude')) {
            userLatLng = LatLng(location['latitude'], location['longitude']);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                complaintData['subject'] ?? 'No Subject',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text("User ID: $userId"),
              Text("Category: ${complaintData['category'] ?? 'N/A'}"),
              Text("Status: ${complaintData['status'] ?? 'Unknown'}"),
              Text("Created At: ${_formatTimestamp(complaintData['createdAt'])}"),
              const SizedBox(height: 10),
              Text("Description: ${complaintData['description'] ?? 'No description'}"),
              if ((complaintData['adminMessage'] ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    "Admin Message: ${complaintData['adminMessage']}",
                    style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.pink),
                  ),
                ),
              if ((complaintData['imageUrl'] ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      complaintData['imageUrl'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              if (locationSnapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator()),
              if (userLatLng != null)
                SizedBox(
                  height: 300,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: userLatLng,
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('userLocation'),
                        position: userLatLng,
                        infoWindow: const InfoWindow(title: 'User Location'),
                      ),
                    },
                  ),
                )
              else if (locationSnapshot.connectionState == ConnectionState.done)
                const Text("User location not available."),
            ],
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Mark as Resolved'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(fontSize: 18),
          ),
          onPressed: () {
            final messageController = TextEditingController();

            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Mark as Resolved'),
                content: TextField(
                  controller: messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Admin Message (optional)',
                    hintText: 'Add a message for the user',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      messageController.dispose();
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final adminMessage = messageController.text.trim();
                      messageController.dispose();

                      if (complaintId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Complaint ID is missing')),
                        );
                        Navigator.pop(context);
                        return;
                      }

                      try {
                        await FirebaseFirestore.instance.collection('complaints').doc(complaintId).update({
                          'status': 'Resolved',
                          'adminMessage': adminMessage,
                        });

                        await FirebaseFirestore.instance.collection('messages').add({
                          'userId': userId,
                          'title': 'Complaint Resolved',
                          'body': adminMessage.isNotEmpty
                              ? adminMessage
                              : 'Your complaint "${complaintData['subject'] ?? ''}" has been resolved.',
                          'timestamp': FieldValue.serverTimestamp(),
                          'complaintId': complaintId,
                          'read': false,
                        });

                        Navigator.pop(context); // Close dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Marked as resolved and user notified')),
                        );
                      } catch (e) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating complaint: $e')),
                        );
                      }
                    },
                    child: const Text('Update & Notify'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
