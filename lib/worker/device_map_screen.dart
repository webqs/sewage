import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class DeviceMapScreen extends StatefulWidget {
  const DeviceMapScreen({super.key});

  @override
  State<DeviceMapScreen> createState() => _DeviceMapScreenState();
}

class _DeviceMapScreenState extends State<DeviceMapScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> devices = [];
  StreamSubscription? _deviceStream;

  String selectedFilter = "all";

  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _listenToDevices();

    _blinkController =
    AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _deviceStream?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  /// REALTIME DEVICE STREAM
  void _listenToDevices() {
    _deviceStream = supabase
        .from('alerts')
        .stream(primaryKey: ['id'])
        .listen((data) {
      setState(() {
        devices = List<Map<String, dynamic>>.from(data);
      });

      _fitMapToDevices();
    });
  }

  /// AUTO FIT CAMERA
  void _fitMapToDevices() {
    final points = devices
        .where((d) => d['latitude'] != null && d['longitude'] != null)
        .map((d) => LatLng(d['latitude'], d['longitude']))
        .toList();

    if (points.isNotEmpty) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }

  /// CURRENT LOCATION
  Future<void> _goToCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();

    _mapController.move(
      LatLng(position.latitude, position.longitude),
      16,
    );
  }

  /// GOOGLE NAVIGATION
  Future<void> _openNavigation(double lat, double lon) async {
    final Uri url =
    Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lon");

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  /// SEVERITY COLOR
  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case "high":
        return Colors.red;
      case "medium":
        return Colors.orange;
      case "low":
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  /// COUNTS
  int get highCount => devices.where((d) => d['severity'] == 'high').length;
  int get mediumCount => devices.where((d) => d['severity'] == 'medium').length;
  int get lowCount => devices.where((d) => d['severity'] == 'low').length;

  /// DEVICE DETAILS
  void _showDeviceDetails(Map<String, dynamic> device) {
    final lat = device['latitude'];
    final lon = device['longitude'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device['device_name'] ?? "Unknown Device",
                style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              Text("📍 Location: ${device['location']}"),
              Text("🚦 Status: ${device['status']}"),
              Text("⚠ Severity: ${device['severity']}"),

              if (device['flow_rate'] != null)
                Text("🌊 Flow Rate: ${device['flow_rate']} L/min"),

              if (device['water_level'] != null)
                Text("💧 Water Level: ${device['water_level']} cm"),

              if (device['blockage_percent'] != null)
                Text("🧠 AI Blockage: ${device['blockage_percent']} %"),

              const SizedBox(height: 15),

              if (lat != null && lon != null)
                ElevatedButton.icon(
                  onPressed: () => _openNavigation(lat, lon),
                  icon: const Icon(Icons.navigation),
                  label: const Text("Navigate"),
                ),
            ],
          ),
        );
      },
    );
  }

  /// FILTERED DEVICES
  List<Map<String, dynamic>> get filteredDevices {
    if (selectedFilter == "all") return devices;

    return devices.where((d) => d['severity'] == selectedFilter).toList();
  }

  /// SEARCH
  void _searchDevice() {
    showSearch(context: context, delegate: DeviceSearchDelegate(devices));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Device Monitoring Map"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _searchDevice,
          ),
        ],
      ),
      body: devices.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [

          /// MAP
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(9.71472, 76.68694),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate:
                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.sewage',
              ),

              MarkerLayer(
                markers: filteredDevices
                    .where((d) =>
                d['latitude'] != null &&
                    d['longitude'] != null)
                    .map((device) {
                  final severity = device['severity'];

                  return Marker(
                    point: LatLng(
                      device['latitude'],
                      device['longitude'],
                    ),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => _showDeviceDetails(device),
                      child: AnimatedBuilder(
                        animation: _blinkController,
                        builder: (context, child) {
                          return Icon(
                            Icons.location_on,
                            size: severity == "high"
                                ? 40 + _blinkController.value * 10
                                : 40,
                            color: _getSeverityColor(severity),
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          /// FILTER BAR
          Positioned(
            top: 80,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _filterChip("all"),
                _filterChip("high"),
                _filterChip("medium"),
                _filterChip("low"),
              ],
            ),
          ),

          /// SUMMARY
          Positioned(
            top: 15,
            left: 15,
            right: 15,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatusItem("High", highCount, Colors.red),
                    _buildStatusItem(
                        "Medium", mediumCount, Colors.orange),
                    _buildStatusItem("Low", lowCount, Colors.green),
                  ],
                ),
              ),
            ),
          ),

          /// LOCATION BUTTON
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _goToCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(value.toUpperCase()),
        selected: selectedFilter == value,
        onSelected: (_) {
          setState(() {
            selectedFilter = value;
          });
        },
      ),
    );
  }

  Widget _buildStatusItem(String title, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        Text(title),
      ],
    );
  }
}

/// SEARCH CLASS
class DeviceSearchDelegate extends SearchDelegate {
  final List<Map<String, dynamic>> devices;

  DeviceSearchDelegate(this.devices);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () => query = "",
    )
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) {
    final results = devices.where((d) {
      final name = d['device_name']?.toLowerCase() ?? "";
      final location = d['location']?.toLowerCase() ?? "";

      return name.contains(query.toLowerCase()) ||
          location.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) {
        return ListTile(
          title: Text(results[i]['device_name'] ?? "Device"),
          subtitle: Text(results[i]['location'] ?? ""),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}