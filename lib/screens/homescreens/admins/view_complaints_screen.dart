import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ViewComplaintsScreen extends StatelessWidget {
  const ViewComplaintsScreen({Key? key}) : super(key: key);

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    return DateFormat.yMMMd().add_jm().format(timestamp.toDate());
  }

  Future<Map<String, dynamic>?> _fetchUserLocation(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('locations').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null &&
            data.containsKey('latitude') &&
            data.containsKey('longitude')) {
          return data;
        }
      }
    } catch (e) {
      debugPrint("Error fetching location for user $userId: $e");
    }
    return null;
  }

  void _openComplaintDetailScreen(BuildContext context, Map<String, dynamic> complaintData) {
    final id = complaintData['id'] ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComplaintDetailScreen(
          complaintData: {...complaintData, 'id': id},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Complaints'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final complaints = snapshot.data?.docs ?? [];

          if (complaints.isEmpty) {
            return const Center(child: Text('No complaints found.'));
          }

          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final doc = complaints[index];
              final data = doc.data() as Map<String, dynamic>;
              final id = doc.id;
              final userId = data['userId'] ?? '';

              return FutureBuilder<Map<String, dynamic>?>(
                future: _fetchUserLocation(userId),
                builder: (context, locationSnapshot) {
                  final locationData = locationSnapshot.data;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 3,
                    child: ListTile(
                      onTap: () => _openComplaintDetailScreen(
                        context,
                        {...data, 'id': id},
                      ),
                      title: Text(data['subject'] ?? 'No subject'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("User ID: $userId"),
                          Text("Category: ${data['category'] ?? 'N/A'}"),
                          Text("Status: ${data['status'] ?? 'Unknown'}"),
                          Text("Date: ${_formatTimestamp(data['createdAt'])}"),
                          const SizedBox(height: 4),
                          Text("Description: ${data['description'] ?? 'No description'}"),
                          if ((data['adminMessage'] ?? '').toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                "Admin Message: ${data['adminMessage']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.pinkAccent,
                                ),
                              ),
                            ),
                          if ((data['imageUrl'] ?? '').toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  data['imageUrl'],
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          const SizedBox(height: 6),
                          if (locationSnapshot.connectionState == ConnectionState.waiting)
                            const Text("Fetching location..."),
                          if (locationData != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Last Known Location:"),
                                Text("Latitude: ${locationData['latitude']}"),
                                Text("Longitude: ${locationData['longitude']}"),
                                if (locationData['timestamp'] != null)
                                  Text("Updated: ${_formatTimestamp(locationData['timestamp'])}"),
                              ],
                            )
                          else if (locationSnapshot.connectionState == ConnectionState.done)
                            const Text(
                              "User location is not available.",
                              style: TextStyle(color: Colors.redAccent, fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            tooltip: 'Mark as Resolved',
                            onPressed: () {
                              final TextEditingController messageController = TextEditingController();

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
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final adminMessage = messageController.text.trim();

                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('complaints')
                                              .doc(id)
                                              .update({
                                            'status': 'Resolved',
                                            'adminMessage': adminMessage,
                                          });

                                          await FirebaseFirestore.instance.collection('messages').add({
                                            'userId': userId,
                                            'title': 'Complaint Resolved',
                                            'body': adminMessage.isNotEmpty
                                                ? adminMessage
                                                : 'Your complaint "${data['subject'] ?? ''}" has been resolved.',
                                            'timestamp': FieldValue.serverTimestamp(),
                                            'complaintId': id,
                                            'read': false,
                                          });

                                          Navigator.pop(context);

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text('Complaint marked as resolved and user notified.'),
                                              backgroundColor: Colors.green[700],
                                              duration: const Duration(seconds: 3),
                                            ),
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

                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            tooltip: 'Delete Complaint',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Complaint'),
                                  content: const Text(
                                      'Are you sure you want to delete this complaint? This action cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          await FirebaseFirestore.instance.collection('complaints').doc(id).delete();
                                          Navigator.pop(context);

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text('Complaint deleted successfully.'),
                                              backgroundColor: Colors.green[700],
                                              duration: const Duration(seconds: 3),
                                            ),
                                          );
                                        } catch (e) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error deleting complaint: $e')),
                                          );
                                        }
                                      },
                                      child: const Text('Delete'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

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
        if (data != null &&
            data.containsKey('latitude') &&
            data.containsKey('longitude')) {
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
          if (location != null &&
              location.containsKey('latitude') &&
              location.containsKey('longitude')) {
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
              if ((complaintData['adminMessage'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    "Admin Message: ${complaintData['adminMessage']}",
                    style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.pink),
                  ),
                ),
              if ((complaintData['imageUrl'] ?? '').toString().isNotEmpty)
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
                const Text(
                  "User location not available.",
                  style: TextStyle(color: Colors.redAccent, fontStyle: FontStyle.italic),
                ),
            ],
          );
        },
      ),
    );
  }
}
