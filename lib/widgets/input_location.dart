import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:favorite_places_app/models/place.dart';
import 'package:favorite_places_app/screens/maps.dart';

class InputLocation extends StatefulWidget {
  const InputLocation({super.key, required this.onSelectLocation});
  final void Function(PlaceLocation location) onSelectLocation;

  @override
  State<InputLocation> createState() => _InputLocationState();
}

class _InputLocationState extends State<InputLocation> {
  PlaceLocation? _pickedLocation;
  var _isGettingLocation = false;
  String? _address;

  // 🌍 Free Reverse Geocoding with OpenStreetMap Nominatim
  Future<String> _getAddress(double lat, double lng) async {
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng';

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'FlutterApp/1.0'}, // Better user agent
      );

      if (response.statusCode != 200) return 'Unknown location';

      final data = json.decode(response.body);
      return data['display_name'] ?? 'Unknown location';
    } catch (e) {
      return 'Unknown location';
    }
  }

  Future<void> _savePlace(double latitude, double longitude) async {
    setState(() {
      _isGettingLocation = true;
    });

    final address = await _getAddress(latitude, longitude);

    setState(() {
      _pickedLocation = PlaceLocation(
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
      _address = address;
      _isGettingLocation = false;
    });

    widget.onSelectLocation(_pickedLocation!);
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied'),
            ),
          );
        }
        return;
      }

      setState(() {
        _isGettingLocation = true;
      });

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _savePlace(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _isGettingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    }
  }

  void _selectOnMap() async {
    try {
      final pickedLocation = await Navigator.of(context).push<gmap.LatLng>(
        MaterialPageRoute(builder: (context) => const MapsScreen()),
      );

      if (pickedLocation == null) return;

      await _savePlace(pickedLocation.latitude, pickedLocation.longitude);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting location: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget previewContent = const Text(
      "No location chosen.",
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.grey, fontSize: 16),
    );

    if (_pickedLocation != null) {
      previewContent = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(
              _pickedLocation!.latitude,
              _pickedLocation!.longitude,
            ),
            initialZoom: 16,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none, // Disable interactions for preview
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(
                    _pickedLocation!.latitude,
                    _pickedLocation!.longitude,
                  ),
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_isGettingLocation) {
      previewContent = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Getting location...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          height: 170,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              width: 1,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: previewContent,
        ),
        const SizedBox(height: 8),
        if (_address != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _address!,
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton.icon(
                  onPressed: _isGettingLocation ? null : _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Current Location'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton.icon(
                  onPressed: _isGettingLocation ? null : _selectOnMap,
                  icon: const Icon(Icons.map),
                  label: const Text('Select on Map'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
