// lib/services/location_service.dart (NAYI FILE)
import 'dart:async';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:location/location.dart';

class LocationService {
  final ApiService _apiService;
  Timer? _locationTimer;
  final Location _location = Location();

  LocationService(this._apiService);

  // Yeh function HomeDrawer se call hoga jab user "Online" switch karega
  void startLocationUpdates() async {
    // Agar timer pehle se chal raha hai, toh kuch na karein
    if (_locationTimer != null && _locationTimer!.isActive) return;

    print("Starting location service...");

    // Pehle permissions check karein
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return; // User ne service enable nahi ki
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return; // User ne permission nahi di
    }
    
    // Pehli baar location turant bhejein
    _sendLocationUpdate();

    // Ab har 5 minute mein location bhej ne ke liye timer set karein
    _locationTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _sendLocationUpdate();
    });
  }

  // Yeh function HomeDrawer se call hoga jab user "Offline" switch karega
  void stopLocationUpdates() {
    print("Stopping location service...");
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  // Asli function jo location fetch karke backend ko bhejta hai
  Future<void> _sendLocationUpdate() async {
    try {
      final LocationData locationData = await _location.getLocation();
      
      if (locationData.latitude != null && locationData.longitude != null) {
        print("Sending location update: ${locationData.latitude}, ${locationData.longitude}");
        
        // Backend API ko call karein
        await _apiService.post(
          '/specialist/profile/update-location/', 
          {
            'latitude': locationData.latitude.toString(),
            'longitude': locationData.longitude.toString(),
          }
        );
      }
    } catch (e) {
      print("Failed to send location update: $e");
    }
  }
}