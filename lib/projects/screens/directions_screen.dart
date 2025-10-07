// lib/projects/screens/directions_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:apna_thekedar_specialist/services/directions_service.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:iconsax/iconsax.dart';
import 'package:location/location.dart';
import 'package:flutter_compass/flutter_compass.dart';

class DirectionsScreen extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;

  const DirectionsScreen({
    super.key,
    required this.origin,
    required this.destination,
  });

  @override
  State<DirectionsScreen> createState() => _DirectionsScreenState();
}

class _DirectionsScreenState extends State<DirectionsScreen> {
  late GoogleMapController _mapController;
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;

  TravelMode _selectedMode = TravelMode.driving;
  String? _distance;
  String? _duration;
  List<Map<String, dynamic>> _steps = [];

  final Set<Marker> _markers = {};
  LocationData? _currentLocation;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _compassSubscription;
  double _currentHeading = 0;
  final Location _locationService = Location();
  BitmapDescriptor? _navigationIcon;

  // View control karne ke liye naya variable
  bool _isListView = false;

  @override
  void initState() {
    super.initState();
    _setInitialMarkers();
    _setMarkersAndRoute(_selectedMode);
    _initLocationListener();
    _loadNavigationIcon();
  }

  Future<void> _loadNavigationIcon() async {
    // Make sure 'assets/navigation_arrow.png' exists in your project
    _navigationIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/navigation_arrow.png',
    );
  }

  Future<void> _initLocationListener() async {
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _locationService.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationService.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _locationSubscription =
        _locationService.onLocationChanged.listen((LocationData newLocation) {
      if (mounted) {
        setState(() {
          _currentLocation = newLocation;
          _updateCurrentLocationMarker();
        });
      }
    });

    if (FlutterCompass.events != null) {
      _compassSubscription =
          FlutterCompass.events!.listen((CompassEvent event) {
        if (mounted && event.heading != null) {
          setState(() {
            _currentHeading = event.heading!;
            _updateCurrentLocationMarker();
          });
        }
      });
    }
  }

  void _setInitialMarkers() {
    _markers.add(Marker(
      markerId: const MarkerId('origin'),
      position: widget.origin,
      infoWindow: const InfoWindow(title: 'Start Point'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    ));
    _markers.add(Marker(
      markerId: const MarkerId('destination'),
      position: widget.destination,
      infoWindow: const InfoWindow(title: 'Project Location'),
    ));
  }

  void _updateCurrentLocationMarker() {
    if (_currentLocation == null || !mounted) return;

    final lat = _currentLocation!.latitude!;
    final lng = _currentLocation!.longitude!;
    final currentPosition = LatLng(lat, lng);

    _markers.removeWhere((m) => m.markerId.value == 'currentLocation');

    final icon = _selectedMode == TravelMode.walking
        ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose)
        : _navigationIcon;

    if (icon != null) {
      setState(() {
        _markers.add(Marker(
          markerId: const MarkerId('currentLocation'),
          position: currentPosition,
          icon: icon,
          rotation: _currentHeading,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndex: 2,
        ));
      });
    }
  }

  Future<void> _setMarkersAndRoute(TravelMode mode) async {
    setState(() => _isLoading = true);
    _polylines.clear();
    _steps = [];

    final directionsService = DirectionsService();
    final directions = await directionsService.getDirections(
        widget.origin, widget.destination, mode);

    if (directions != null &&
        directions['polyline_points'].isNotEmpty &&
        mounted) {
      _mapController.animateCamera(
          CameraUpdate.newLatLngBounds(directions['bounds'], 50));
      setState(() {
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: directions['polyline_points'],
          color: Colors.blue.shade700,
          width: 6,
        ));
        _distance = directions['total_distance'];
        _duration = directions['total_duration'];
        _steps = directions['steps'] ?? [];
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not find a route for ${mode.name}.')),
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _goToNavigationMode() {
    if (_currentLocation == null) return;
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          zoom: 18.5,
          tilt: 50.0,
          bearing: _currentHeading,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _compassSubscription?.cancel();
    super.dispose();
  }

  String _parseHtmlString(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
  }

  IconData _getManeuverIcon(String? maneuver) {
    switch (maneuver) {
      case 'turn-left':
        return Iconsax.arrow_left_2;
      case 'turn-right':
        return Iconsax.arrow_right_2;
      case 'turn-sharp-left':
        return Iconsax.arrow_left_1;
      case 'turn-sharp-right':
        return Iconsax.arrow_right_1;
      case 'uturn-left':
      case 'uturn-right':
        return Iconsax.repeate_one;
      case 'roundabout-left':
      case 'roundabout-right':
        return Iconsax.rotate_left;
      default:
        return Iconsax.direct_up;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () {
            if (_isListView) {
              setState(() => _isListView = false);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(_isListView ? "Step-by-step" : "Directions to Project"),
        actions: [
          if (_isListView)
            IconButton(
              icon: const Icon(Iconsax.map_1),
              tooltip: 'Show Map View',
              onPressed: () => setState(() => _isListView = false),
            ),
        ],
      ),
      body: _isListView ? _buildStepsList() : _buildMapView(),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (controller) => _mapController = controller,
          initialCameraPosition:
              CameraPosition(target: widget.origin, zoom: 14),
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
        Positioned(
            top: 10, left: 0, right: 0, child: _buildTravelModeSelector()),
        if (_distance != null && _duration != null && !_isLoading)
          Positioned(
              bottom: 20, left: 20, right: 20, child: _buildRouteInfoCard()),
        if (_currentLocation != null)
          Positioned(
            bottom: 95,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'navigation_button',
              onPressed: _goToNavigationMode,
              backgroundColor: Colors.white,
              child: Icon(Iconsax.direct_up, color: Colors.blue.shade700),
            ),
          ),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildStepsList() {
    if (_steps.isEmpty) {
      return const Center(child: Text("No steps available for this route."));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(8.0),
      itemCount: _steps.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final step = _steps[index];
        final maneuver = step['maneuver'];
        final instruction = _parseHtmlString(step['html_instructions'] ?? '');
        final distance = step['distance']?['text'] ?? '';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade50,
            child:
                Icon(_getManeuverIcon(maneuver), color: Colors.blue.shade700),
          ),
          title: Text(instruction),
          trailing:
              Text(distance, style: TextStyle(color: Colors.grey.shade700)),
        );
      },
    );
  }

  Widget _buildTravelModeSelector() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25.0),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5)
            ]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModeIcon(TravelMode.driving, Iconsax.car, 'Car'),
            const SizedBox(width: 16),
            const Icon(Icons.directions_bike, size: 40, color: Colors.blue),
            const SizedBox(width: 20),
            const Icon(Icons.directions_walk, size: 40, color: Colors.green),
            const SizedBox(width: 16),
            _buildModeIcon(TravelMode.transit, Iconsax.bus, 'Public'),
          ],
        ),
      ),
    );
  }

  Widget _buildModeIcon(TravelMode mode, IconData icon, String tooltip) {
    final bool isSelected = _selectedMode == mode;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            setState(() => _selectedMode = mode);
            _setMarkersAndRoute(mode);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade100 : Colors.transparent,
              shape: BoxShape.circle),
          child: Icon(icon,
              color: isSelected ? Colors.blue.shade800 : Colors.grey.shade600,
              size: 28),
        ),
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    return GestureDetector(
      onTap: () => setState(() => _isListView = true),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Iconsax.clock, color: Colors.blue.shade700, size: 22),
              const SizedBox(width: 8),
              Text(_duration!,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              const Icon(Iconsax.ruler, color: Colors.blue, size: 22),
              const SizedBox(width: 8),
              Flexible(
                  child: Text(_distance!,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }
}