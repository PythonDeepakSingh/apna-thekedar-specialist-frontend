// lib/services/directions_service.dart

import 'dart:convert'; // JSON ke liye
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http; // API call ke liye

class DirectionsService {
  // >>> APNI GOOGLE MAPS API KEY YAHAN DAALEIN <<<
  // Yeh key "Directions API" ke liye enabled honi chahiye
  final String _apiKey = "AIzaSyCNMGxpTs6Ln-E0r-sMMmX46gFrUx6jY_Y";

  // === PURANA FUNCTION HATA KAR YEH NAYA FUNCTION BANAYA HAI ===
  Future<Map<String, dynamic>?> getDirections(
    LatLng origin,
    LatLng destination,
    TravelMode travelMode,
  ) async {
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=${travelMode.name.toLowerCase()}&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if ((jsonResponse['routes'] as List).isEmpty) {
          print("Directions API Error: No routes found.");
          return null;
        }

        final route = jsonResponse['routes'][0];
        final leg = route['legs'][0];

        // 1. Polyline points nikalein
        final String polylineString = route['overview_polyline']['points'];
        final List<LatLng> points = PolylinePoints()
            .decodePolyline(polylineString)
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        // 2. Bounds (camera area) nikalein
        final northeast = route['bounds']['northeast'];
        final southwest = route['bounds']['southwest'];
        final bounds = LatLngBounds(
          southwest: LatLng(southwest['lat'], southwest['lng']),
          northeast: LatLng(northeast['lat'], northeast['lng']),
        );

        // 3. Distance aur Duration nikalein
        final String totalDistance = leg['distance']['text'];
        final String totalDuration = leg['duration']['text'];

        // Saari jaankari ek map mein return karein
        final List<Map<String, dynamic>> steps = List<Map<String, dynamic>>.from(leg['steps']);
        return {
          'bounds': bounds,
          'polyline_points': points,
          'total_distance': totalDistance,
          'total_duration': totalDuration,
          'steps': steps,
        };
      } else {
        print("Directions API Error: ${json.decode(response.body)['error_message']}");
        return null;
      }
    } catch (e) {
      print("An error occurred in DirectionsService: $e");
      return null;
    }
  }
}