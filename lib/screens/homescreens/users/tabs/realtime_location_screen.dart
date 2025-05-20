import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class RealtimeLocationScreen extends StatefulWidget {
  const RealtimeLocationScreen({Key? key}) : super(key: key);

  @override
  State<RealtimeLocationScreen> createState() => _RealtimeLocationScreenState();
}

class _RealtimeLocationScreenState extends State<RealtimeLocationScreen> {
  final Completer<gmaps.GoogleMapController> _controller = Completer();
  StreamSubscription<Position>? _positionStreamSubscription;

  gmaps.CameraPosition? _currentCameraPosition;
  gmaps.Marker? _currentLocationMarker;
  Set<gmaps.Marker> _placeMarkers = {};

  // Replace with your actual Google Places API key
  final String googlePlacesApiKey = 'AIzaSyA7u52fa4UbfXrI8LPQ5gvg5tcXYmC6zeE';

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    _updateLocation(position);

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position pos) {
      _updateLocation(pos);
    });
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      return false;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        return false;
      }
    }

    return true;
  }

  void _updateLocation(Position position) async {
    final gmaps.LatLng latLng = gmaps.LatLng(position.latitude, position.longitude);

    setState(() {
      _currentCameraPosition = gmaps.CameraPosition(target: latLng, zoom: 16);
      _currentLocationMarker = gmaps.Marker(
        markerId: const gmaps.MarkerId('currentLocation'),
        position: latLng,
        infoWindow: const gmaps.InfoWindow(title: 'You are here'),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRose),
      );
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('locations').doc(uid).set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    final gmaps.GoogleMapController controller = await _controller.future;
    controller.animateCamera(gmaps.CameraUpdate.newCameraPosition(_currentCameraPosition!));
  }

  Future<void> _fetchNearbyPlaces({required String placeType, String? keyword}) async {
    if (_currentCameraPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location not available')),
      );
      return;
    }

    final lat = _currentCameraPosition!.target.latitude;
    final lng = _currentCameraPosition!.target.longitude;

    String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng'
        '&radius=5000'
        '&key=$googlePlacesApiKey';

    if (keyword != null && keyword.isNotEmpty) {
      url += '&keyword=${Uri.encodeComponent(keyword)}';
    } else {
      url += '&type=$placeType';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final places = data['results'] as List<dynamic>;

        if (places.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No nearby places found')),
          );
          return;
        }

        Set<gmaps.Marker> newMarkers = places.map((place) {
          final loc = place['geometry']['location'];
          final placeId = place['place_id'];
          final name = place['name'];
          final lat = loc['lat'];
          final lng = loc['lng'];

          gmaps.BitmapDescriptor icon;
          if (placeType == 'police') {
            icon = gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueBlue);
          } else {
            // For pink booths or other keywords
            icon = gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRose);
          }

          return gmaps.Marker(
            markerId: gmaps.MarkerId(placeId),
            position: gmaps.LatLng(lat, lng),
            infoWindow: gmaps.InfoWindow(title: name),
            icon: icon,
          );
        }).toSet();

        setState(() {
          _placeMarkers = newMarkers;
          if (_currentLocationMarker != null) {
            _placeMarkers.add(_currentLocationMarker!);
          }
        });

        final firstLoc = places[0]['geometry']['location'];
        final gmaps.GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          gmaps.CameraUpdate.newLatLngZoom(
            gmaps.LatLng(firstLoc['lat'], firstLoc['lng']),
            14,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Places API error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching places: $e')),
      );
    }
  }

  Future<void> _shareLocation() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    final trustedContactsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trusted_contacts')
        .get();

    if (trustedContactsSnap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No trusted contacts found')),
      );
      return;
    }

    final selectedContact = await showDialog<DocumentSnapshot>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Select Contact to Share Location'),
          children: trustedContactsSnap.docs.map((doc) {
            final data = doc.data();
            final name = (data['name'] ?? 'Unknown').toString();
            final relation = (data['relation'] ?? '').toString();
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, doc),
              child: Text('$name ($relation)'),
            );
          }).toList(),
        );
      },
    );

    if (selectedContact == null) return;

    final data = selectedContact.data() as Map<String, dynamic>?;

    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected contact data is empty')),
      );
      return;
    }

    final phone = (data['phone'] ?? '').toString();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected contact has no phone number')),
      );
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final lat = position.latitude;
      final lng = position.longitude;

      final smsUri = Uri.parse(
          'sms:$phone?body=My current location: https://maps.google.com/?q=$lat,$lng');

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location shared with ${data['name']}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open SMS app')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share location: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = <gmaps.Marker>{};
    if (_currentLocationMarker != null) markers.add(_currentLocationMarker!);
    markers.addAll(_placeMarkers);

    return Scaffold(
      appBar: AppBar(title: const Text('Realtime Location')),
      body: Stack(
        children: [
          if (_currentCameraPosition != null)
            gmaps.GoogleMap(
              mapType: gmaps.MapType.normal,
              initialCameraPosition: _currentCameraPosition!,
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (controller) => _controller.complete(controller),
            )
          else
            const Center(child: CircularProgressIndicator()),
          Positioned(
            top: 16,
            left: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'police',
                  backgroundColor: Colors.blue.shade700,
                  onPressed: () => _fetchNearbyPlaces(placeType: 'police'),
                  tooltip: 'Show Nearby Police Stations',
                  child: const Icon(Icons.local_police),
                  mini: true,
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'women_booth',
                  backgroundColor: Colors.pink.shade400,
                  onPressed: () => _fetchNearbyPlaces(keyword: 'women pink booth', placeType: ''),
                  tooltip: 'Show Nearby Pink Booths',
                  child: const Icon(Icons.woman),
                  mini: true,
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'share_location',
                  backgroundColor: Colors.green.shade600,
                  onPressed: _shareLocation,
                  tooltip: 'Share Location with Trusted Contact',
                  child: const Icon(Icons.share_location),
                  mini: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
