// lib/onboarding/screens/set_operating_address.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import 'package:iconsax/iconsax.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'dart:convert';
import 'package:apna_thekedar_specialist/splash_screen.dart';
import 'package:apna_thekedar_specialist/onboarding/screens/place_search_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apna_thekedar_specialist/onboarding/screens/select_services_screen.dart';


class SetOperatingAddressScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const SetOperatingAddressScreen({super.key, required this.profileData});

  @override
  State<SetOperatingAddressScreen> createState() => _SetOperatingAddressScreenState();
}

class _SetOperatingAddressScreenState extends State<SetOperatingAddressScreen> {
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  Placemark? _selectedPlacemark;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(28.6139, 77.2090),
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        String line1 = [place.name, place.street].where((s) => s != null && s.isNotEmpty).join(', ');
        String line2 = [place.subLocality, place.locality, place.postalCode].where((s) => s != null && s.isNotEmpty).join(', ');

        if (mounted) {
          setState(() {
            _selectedPlacemark = place;
            _addressLine1Controller.text = line1;
            _addressLine2Controller.text = line2;
            _selectedLocation = position;
          });
        }
      }
    } catch (e) {
      print("Error getting address: $e");
    }
  }
  
  // ==================== YAHAN PAR HAI FIX ====================
  Future<void> _getCurrentLocation() async {
    loc.Location location = loc.Location();
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) return; // Agar user service on na kare, to kuch na karein
      }

      loc.PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) return; // Agar user permission na de, to kuch na karein
      }
      
      // Live location fetch karein
      final locationData = await location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        final latLng = LatLng(locationData.latitude!, locationData.longitude!);
        
        // Map ko user ki live location par le jayein
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15.0));
      }
    } catch(e) {
      print("Could not get current location: $e");
      // Agar live location lene mein koi error aaye, to user ko pareshan na karein
      // Map Delhi par hi aaram se tika rahega
    }
  }
  // ==================== FIX YAHAN KHATAM HUA ====================


  void _navigateToSearchPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlaceSearchScreen()),
    );
    if (result != null && result is Map) {
      final location = result['geometry']['location'];
      final latLng = LatLng(location['lat'], location['lng']);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15.0));
    }
  }

// ==================== YAHAN PAR HAI ASLI FIX ====================
  Future<void> _saveProfileAndAddresses() async {
    if (_selectedLocation == null || _selectedPlacemark == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a valid location.')));
      return;
    }
    setState(() { _isLoading = true; });

    try {
      // Step 1: Profile create karein
      final profileResponse = await _apiService.post('/specialist/profile/create/', {
        'bio': widget.profileData['bio'],
        'experience_years': widget.profileData['experience_years'],
      });

      // Agar pehla step hi fail ho jaaye, to aage na badhein
      if (!mounted || profileResponse.statusCode != 201) {
        throw Exception('Failed to create profile: ${profileResponse.body}');
      }

      // Step 2: Permanent Address create karein
      final permanentAddressResponse = await _apiService.post('/specialist/address/create/', {
          'address_type': 'PERMANENT',
          'address': widget.profileData['permanent_address'],
          'pincode': widget.profileData['permanent_pincode'],
      });

      // Agar doosra step fail ho jaaye, to aage na badhein
      if (!mounted || permanentAddressResponse.statusCode != 201) {
        throw Exception('Failed to save permanent address: ${permanentAddressResponse.body}');
      }

      // Step 3: Operating Address create karein
      final operatingAddressResponse = await _apiService.post('/specialist/address/create/', {
          'address_type': 'CURRENT',
          'address': "${_addressLine1Controller.text}, ${_addressLine2Controller.text}",
          'pincode': _selectedPlacemark!.postalCode ?? "",
          'latitude': _selectedLocation!.latitude.toStringAsFixed(6),
          'longitude': _selectedLocation!.longitude.toStringAsFixed(6),
      });
      // Agar teesra step bhi safal ho, tabhi aage badhein
      if (mounted && operatingAddressResponse.statusCode == 201) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('draft_bio');
          await prefs.remove('draft_experience');
          await prefs.remove('draft_permanent_address');
          await prefs.remove('draft_pincode');
          

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile setup complete!')),
          );
          
         Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SelectServicesScreen()),
            (route) => false,
          );
      } else {
        throw Exception('Failed to save operating address: ${operatingAddressResponse.body}');
      }
    } catch (e) {
      // Agar kisi bhi step mein error aaye, to user ko batayein
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      // Chahe success ho ya fail, loading indicator ko band karein
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }
  // ==================== FIX YAHAN KHATAM HUA ====================

  @override
  Widget build(BuildContext context) {
    // Baaki ka UI code bilkul waisa hi hai
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Operating Address (2/2)'),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
          children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (controller) => _mapController = controller,
            onCameraIdle: () async {
              if (_mapController == null) return;
              final latLng = await _mapController!.getLatLng(
                ScreenCoordinate(
                  x: MediaQuery.of(context).size.width ~/ 2,
                  y: (MediaQuery.of(context).size.height - kToolbarHeight) ~/ 2,
                ),
              );
              _getAddressFromLatLng(latLng);
            },
          ),
          
          const Center(child: Icon(Iconsax.location5, color: Colors.red, size: 40)),

          Positioned(
            top: 10, left: 15, right: 15,
            child: GestureDetector(
              onTap: _navigateToSearchPage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                ),
                child: const Row(
                  children: [
                    Icon(Iconsax.search_normal_1, color: Colors.grey),
                    SizedBox(width: 10),
                    Text("Search for area, street name..."),
                  ],
                ),
              ),
            ),
          ),
          
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0,-2))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _addressLine1Controller,
                    decoration: const InputDecoration(labelText: 'House No. / Street Name'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _addressLine2Controller,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Area / City / Pincode',
                      fillColor: Colors.grey[200],
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Iconsax.location),
                          label: const Text('Live Location'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfileAndAddresses,
                          child: _isLoading
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : const Text('Finish Setup'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}