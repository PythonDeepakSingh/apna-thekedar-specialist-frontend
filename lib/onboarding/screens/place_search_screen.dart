// lib/onboarding/screens/place_search_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iconsax/iconsax.dart';

class PlaceSearchScreen extends StatefulWidget {
  const PlaceSearchScreen({super.key});

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  // IMPORTANT: Is key ko production mein aisi jagah rakhein jahan se yeh safe rahe
  final String _apiKey = "AIzaSyCNMGxpTs6Ln-E0r-sMMmX46gFrUx6jY_Y"; 
  List<dynamic> _placesList = [];
  bool _isLoading = false;

  // Search ke liye function
  Future<void> _searchPlaces(String input) async {
    if (input.length < 3) {
      if (mounted) setState(() => _placesList = []);
      return;
    }
    // Hum sirf India mein search kar rahe hain
    String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_apiKey&sessiontoken=12345&components=country:in';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _placesList = json.decode(response.body)['predictions'];
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  // Selected place ki details (lat/lng) nikalne ke liye function
  Future<void> _getPlaceDetails(String placeId) async {
    if (mounted) setState(() => _isLoading = true);
    String url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        if (mounted) {
          final data = json.decode(response.body);
          // Hum pichli screen par poori detail wapas bhejenge
          Navigator.pop(context, data['result']);
        }
      }
    } catch (e) {
      print(e);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Location'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _searchPlaces,
              decoration: const InputDecoration(
                hintText: 'Search your address...',
                prefixIcon: Icon(Iconsax.search_normal_1),
              ),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _placesList.length,
              itemBuilder: (context, index) {
                final place = _placesList[index];
                return ListTile(
                  leading: const Icon(Iconsax.location, color: Colors.grey),
                  title: Text(place['structured_formatting']['main_text']),
                  subtitle: Text(place['structured_formatting']['secondary_text']),
                  onTap: () {
                    _getPlaceDetails(place['place_id']);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}