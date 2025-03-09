import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'vendor_menu_screen.dart';

class NearbyVendorsScreen extends StatefulWidget {
  const NearbyVendorsScreen({super.key});

  @override
  State<NearbyVendorsScreen> createState() => _NearbyVendorsScreenState();
}

class _NearbyVendorsScreenState extends State<NearbyVendorsScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location services are disabled.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Location permissions are denied.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permissions are permanently denied.';
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error getting location: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nearby Vendors')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessage, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _getCurrentLocation,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Vendors'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vendors')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final vendors = snapshot.data?.docs ?? [];

          if (vendors.isEmpty) {
            return const Center(
              child: Text('No vendors found nearby'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: vendors.length,
            itemBuilder: (context, index) {
              final vendor = vendors[index].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  leading: vendor['imageUrl'] != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(vendor['imageUrl']),
                        )
                      : const CircleAvatar(child: Icon(Icons.store)),
                  title: Text(vendor['businessName'] ?? 'Unknown Vendor'),
                  subtitle: Text(vendor['address'] ?? 'No address'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VendorMenuScreen(
                          upiId: vendor['upiId'],
                          vendorName: vendor['businessName'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
