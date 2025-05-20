import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';


import 'package:wsa4/screens/homescreens/users/news/news_service.dart';
import 'package:wsa4/screens/homescreens/users/tabs/edit_profile.dart';
import 'package:wsa4/screens/homescreens/users/tabs/online_complaint_screen.dart';
import 'package:wsa4/screens/homescreens/users/trusted_contacts_section.dart';
import 'package:wsa4/screens/homescreens/users/tabs/realtime_location_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  String? username;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            username = doc.get('username');
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch username: $e');
    }
  }

  void _onTabSelected(int index) {
    // Skip the FAB's center slot (index 2)
    if (index == 2) return;
    setState(() {
      _selectedIndex = index > 2 ? index - 1 : index;
    });
  }

  Future<void> _handleSosPressed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to send SOS')),
      );
      return;
    }

    // Request location permission
    final permissionStatus = await Permission.locationWhenInUse.request();
    if (!permissionStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required to send SOS')),
      );
      return;
    }

    // Get current location
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get current location')),
      );
      return;
    }

    // Fetch trusted contacts phone numbers from Firestore
    List<String> trustedNumbers = [];
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('trusted_contacts')
          .get();

      for (var doc in snapshot.docs) {
        final phone = doc.get('phone') as String?;
        if (phone != null && phone.isNotEmpty) {
          trustedNumbers.add(phone);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch trusted contacts')),
      );
      return;
    }

    if (trustedNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No trusted contacts found')),
      );
      return;
    }

    // Compose SOS message with Google Maps link
    final mapsLink = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
    final messageBody = '🚨 SOS Alert! I need help. My current location: $mapsLink';

    // Construct sms: URI with multiple recipients
    final smsUri = Uri(
      scheme: 'sms',
      path: trustedNumbers.join(','),
      queryParameters: {'body': messageBody},
    );

    // Launch SMS app
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open SMS app')),
      );
      return;
    }

    // Log the SOS event to Firestore notifications
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': user.uid,
        'type': 'sos',
        'message': messageBody,
        'timestamp': FieldValue.serverTimestamp(),
        'location': GeoPoint(position.latitude, position.longitude),
        'sentTo': trustedNumbers,
        'status': 'sent',
      });
    } catch (e) {
      debugPrint('Failed to save SOS notification: $e');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SOS message is ready to send in your SMS app')),
    );
  }

  final List<Widget> _screens = const [
    _HomeTab(),
    RealtimeLocationScreen(),
    OnlineComplaintPage(),
    EditProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: username == null ? const Text('Loading...') : Text('Hello, $username!'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                // Handle notifications tap
              },
            ),
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: () {
                // Handle messages tap
              },
            ),
          ],
        ),
      ),
      body: SafeArea(child: _screens[_selectedIndex]),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleSosPressed,
        backgroundColor: Theme.of(context).floatingActionButtonTheme.backgroundColor,
        tooltip: 'SOS',
        child: const Icon(Icons.warning, size: 36),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 0, 'Home'),
              _buildNavItem(Icons.location_on, 1, 'Location'),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(Icons.report_problem, 3, 'Complaint'),
              _buildNavItem(Icons.account_circle, 4, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String label) {
    final isSelected = _selectedIndex == (index > 2 ? index - 1 : index);
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey;
    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  Future<void> _callNumber(BuildContext context, String number) async {
    final Uri telUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot call $number')),
      );
    }
  }

  Future<void> _openMapSearch(BuildContext context, String query) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open map for "$query"')),
      );
    }
  }

  Widget _buildEmergencyCard(BuildContext context, String iconPath, String label, String phoneNumber) {
    return InkWell(
      onTap: () => _callNumber(context, phoneNumber),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconPath, height: 40),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(phoneNumber, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceIcon(BuildContext context, String iconPath, String label, String query) {
    return InkWell(
      onTap: () => _openMapSearch(context, query),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white70,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(10),
            child: Image.asset(iconPath, fit: BoxFit.contain),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Emergency Helpline Numbers',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildEmergencyCard(context, 'assets/icons/police.png', 'Police', '100'),
                _buildEmergencyCard(context, 'assets/icons/ambulance.png', 'Ambulance', '108'),
                _buildEmergencyCard(context, 'assets/icons/womenpolice.png', 'Women Helpline', '1090'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Emergency Services',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildServiceIcon(context, 'assets/icons/police.png', 'Police', 'police'),
                _buildServiceIcon(context, 'assets/icons/hospital.png', 'Hospital', 'hospital'),
                _buildServiceIcon(context, 'assets/icons/pharmacy.png', 'Pharmacy', 'pharmacy'),
                _buildServiceIcon(context, 'assets/icons/firetruck.png', 'Fire', 'fire station'),
                _buildServiceIcon(context, 'assets/icons/metro.png', 'Metro', 'metro station'),
                _buildServiceIcon(context, 'assets/icons/womenpolice.png', 'Pink Booth', 'pink booth'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const TrustedContactsSection(),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Latest Women's Safety News",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          const NewsCarousel(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class NewsCarousel extends StatefulWidget {
  const NewsCarousel({Key? key}) : super(key: key);

  @override
  State<NewsCarousel> createState() => _LatestNewsCarouselState();
}

class _LatestNewsCarouselState extends State<NewsCarousel> {
  late Future<List<NewsArticle>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = NewsService.fetchWomenNews();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NewsArticle>>(
      future: _newsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No news available at the moment.'),
          );
        }

        final newsList = snapshot.data!;
        return CarouselSlider(
          options: CarouselOptions(
            height: 200,
            autoPlay: true,
            enlargeCenterPage: true,
          ),
          items: newsList.map((article) {
            return GestureDetector(
              onTap: () async {
                final uri = Uri.parse(article.url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  image: DecorationImage(
                    image: NetworkImage(article.urlToImage),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    article.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      shadows: [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.black87,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
